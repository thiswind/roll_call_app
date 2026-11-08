import Flutter
import UIKit

/// 接收系统“用其他应用打开”传入的文档 URL。
/// 冷启动先缓存路径，待 Dart 注册 MethodChannel 后读取；运行中直接推送。
public class DocumentImportPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private let channelName = "edu.ynu.isc.rollCallApp/documents"
  private var channel: FlutterMethodChannel?
  private var channelReady = false
  private var pendingPaths = [String]()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = DocumentImportPlugin()
    let channel = FlutterMethodChannel(
      name: instance.channelName,
      binaryMessenger: registrar.messenger()
    )
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    registrar.addSceneDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPendingDocuments":
      channelReady = true
      let paths = pendingPaths
      pendingPaths.removeAll()
      NSLog("[DocumentImport] Dart ready, pending=\(paths)")
      result(paths)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    receiveDocuments([url])
  }

  @available(iOS 13.0, *)
  public func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    let urls = connectionOptions?.urlContexts.map { $0.url } ?? []
    return receiveDocuments(urls)
  }

  @available(iOS 13.0, *)
  public func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) -> Bool {
    receiveDocuments(URLContexts.map { $0.url })
  }

  @discardableResult
  private func receiveDocuments(_ urls: [URL]) -> Bool {
    NSLog("[DocumentImport] URLs: \(urls.map { $0.absoluteString })")
    let paths = urls.filter { $0.isFileURL }.map { $0.path }
    guard !paths.isEmpty else { return false }
    NSLog("[DocumentImport] channelReady=\(channelReady), paths=\(paths)")

    if channelReady {
      channel?.invokeMethod("documentReceived", arguments: paths)
    } else {
      pendingPaths.append(contentsOf: paths)
    }
    return true
  }
}
