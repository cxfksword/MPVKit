import Foundation
import GLKit
import Libmpv

class MPVViewController: UIViewController {
    var glView : MPVOGLView!
    var glContext: EAGLContext!
    private var defaultFBO: GLint = -1
    
    var mpv: OpaquePointer!
    var mpvGL: OpaquePointer!
    lazy var queue = DispatchQueue(label: "mpv", qos: .userInitiated)
    
    var autoPlay: Bool = true
    var playUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUIComponents()
        setupContext()
        setupMpv()
        
        if let url = playUrl, autoPlay {
            loadFile(url)
        }
    }
    
    func setupUIComponents() {
        glView = MPVOGLView(frame: self.view.frame)
        self.view.addSubview(glView)
        glView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glView.topAnchor.constraint(equalTo: self.view.topAnchor),
            glView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            glView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            glView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    
    func setupContext() {
        self.glContext = EAGLContext(api: .openGLES3)!
        if self.glContext == nil {
            print("create context fail ...")
            return
        }
        glView.context = self.glContext
        let isSuccess = EAGLContext.setCurrent(self.glContext)
        if !isSuccess {
            print("setup context fail")
        }
    }
    
    func setupMpv() {
        mpv = mpv_create()
        if mpv == nil {
            print("failed creating context\n")
            exit(1)
        }
        
        // https://mpv.io/manual/stable/#options
#if DEBUG
        checkError(mpv_request_log_messages(mpv, "debug"))
#else
        checkError(mpv_request_log_messages(mpv, "no"))
#endif
        checkError(mpv_set_option_string(mpv, "keep-open", "yes"))
        checkError(mpv_set_option_string(mpv, "subs-match-os-language", "yes"))
        checkError(mpv_set_option_string(mpv, "subs-fallback", "yes"))
        checkError(mpv_set_option_string(mpv, "hwdec", machine == "x86_64" ? "no" : "auto-safe"))
        checkError(mpv_set_option_string(mpv, "vo", "libmpv"))
        
        checkError(mpv_initialize(mpv))
        
        let api = UnsafeMutableRawPointer(mutating: (MPV_RENDER_API_TYPE_OPENGL as NSString).utf8String)
        var initParams = mpv_opengl_init_params(
            get_proc_address: {
                (ctx, name) in
                return MPVViewController.getProcAddress(ctx, name)
            },
            get_proc_address_ctx: nil
        )
        
        withUnsafeMutablePointer(to: &initParams) { initParams in
            var params = [
                mpv_render_param(type: MPV_RENDER_PARAM_API_TYPE, data: api),
                mpv_render_param(type: MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, data: initParams),
                mpv_render_param()
            ]
            
            if mpv_render_context_create(&mpvGL, mpv, &params) < 0 {
                puts("failed to initialize mpv GL context")
                exit(1)
            }
            
            glView.mpvGL = UnsafeMutableRawPointer(mpvGL)
            mpv_render_context_set_update_callback(
                mpvGL,
                glUpdate(_:),
                UnsafeMutableRawPointer(Unmanaged.passUnretained(glView).toOpaque())
            )
        }
        
        mpv_set_wakeup_callback(self.mpv, { (ctx) in
                let client = unsafeBitCast(ctx, to: MPVViewController.self)
                client.readEvents()
            }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }

    
    
    func loadFile(
        _ url: URL
    ) {
        var args = [url.absoluteString]
        var options = [String]()
        
        args.append("replace")
        
        if !options.isEmpty {
            args.append(options.joined(separator: ","))
        }
        
        command("loadfile", args: args)
    }
    
    func command(
        _ command: String,
        args: [String?] = [],
        checkForErrors: Bool = true,
        returnValueCallback: ((Int32) -> Void)? = nil
    ) {
        guard mpv != nil else {
            return
        }
        var cargs = makeCArgs(command, args).map { $0.flatMap { UnsafePointer<CChar>(strdup($0)) } }
        defer {
            for ptr in cargs where ptr != nil {
                free(UnsafeMutablePointer(mutating: ptr!))
            }
        }
        print("\(command) -- \(args)")
        let returnValue = mpv_command(mpv, &cargs)
        if checkForErrors {
            checkError(returnValue)
        }
        if let cb = returnValueCallback {
            cb(returnValue)
        }
    }
    
    private func makeCArgs(_ command: String, _ args: [String?]) -> [String?] {
        if !args.isEmpty, args.last == nil {
            fatalError("Command do not need a nil suffix")
        }
        
        var strArgs = args
        strArgs.insert(command, at: 0)
        strArgs.append(nil)
        
        return strArgs
    }
    
    func readEvents() {
        queue.async { [self] in
            while self.mpv != nil {
                let event = mpv_wait_event(self.mpv, 0)
                if event?.pointee.event_id == MPV_EVENT_NONE {
                    break
                }
   
                switch event!.pointee.event_id {
                case MPV_EVENT_SHUTDOWN:
                    mpv_render_context_free(mpvGL);
                    mpv_terminate_destroy(mpv);
                    mpv = nil;
                    break;
                case MPV_EVENT_LOG_MESSAGE:
                    let msg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event!.pointee.data))
                    print("[\(String(cString: (msg!.pointee.prefix)!))] \(String(cString: (msg!.pointee.level)!)): \(String(cString: (msg!.pointee.text)!))")
                default:
                    let eventName = mpv_event_name(event!.pointee.event_id )
                    print("event: \(String(cString: (eventName)!))");
                }
                 
            }
        }
    }
    
    
    private func checkError(_ status: CInt) {
        if status < 0 {
            print("MPV API error: \(String(cString: mpv_error_string(status)))\n")
        }
    }
    
    private var machine: String {
        var systeminfo = utsname()
        uname(&systeminfo)
        return withUnsafeBytes(of: &systeminfo.machine) { bufPtr -> String in
            let data = Data(bufPtr)
            if let lastIndex = data.lastIndex(where: { $0 != 0 }) {
                return String(data: data[0 ... lastIndex], encoding: .isoLatin1)!
            } else {
                return String(data: data, encoding: .isoLatin1)!
            }
        }
    }
    
    
    private static func getProcAddress(_: UnsafeMutableRawPointer?, _ name: UnsafePointer<Int8>?) -> UnsafeMutableRawPointer? {
        let symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, CFStringBuiltInEncodings.ASCII.rawValue)
        let identifier = CFBundleGetBundleWithIdentifier("com.apple.opengles" as CFString)
        
        return CFBundleGetFunctionPointerForName(identifier, symbolName)
    }

}

private func glUpdate(_ ctx: UnsafeMutableRawPointer?) {
    let glView = unsafeBitCast(ctx, to: MPVOGLView.self)
    
    guard glView.needsDrawing else {
        return
    }
    
    glView.queue.async {
        glView.display()
    }
}
