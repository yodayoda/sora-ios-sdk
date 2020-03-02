import Foundation
import SocketRocket

public class SocketRocketWebSocketChannel: WebSocketChannel {

    public var url: URL
    public var sslEnabled: Bool = true
    public var handlers: WebSocketChannelHandlers = WebSocketChannelHandlers()
    public var internalHandlers: WebSocketChannelHandlers = WebSocketChannelHandlers()

    public var state: ConnectionState {
        get { return context.state }
    }

    var context: SocketRocketWebSocketChannelContext!
    
    public required init(url: URL) {
        self.url = url
        context = SocketRocketWebSocketChannelContext(channel: self)
    }
    
    public func connect(handler: @escaping (Error?) -> Void) {
        context.connect(handler: handler)
    }
    
    public func disconnect(error: Error?) {
        context.disconnect(error: error)
    }
    
    public func send(message: WebSocketMessage) {
        Logger.debug(type: .webSocketChannel, message: "send message")
        context.send(message: message)
    }

}

class SocketRocketWebSocketChannelContext: NSObject, SRWebSocketDelegate {
    
    weak var channel: SocketRocketWebSocketChannel!
    var nativeChannel: SRWebSocket
    
    var state: ConnectionState = .disconnected {
        didSet {
            Logger.trace(type: .webSocketChannel,
                      message: "changed state from \(oldValue) to \(state)")
        }
    }
    
    var onConnect: ((Error?) -> Void)?

    init(channel: SocketRocketWebSocketChannel) {
        self.channel = channel
        nativeChannel = SRWebSocket(url: channel.url)
        super.init()
        nativeChannel.delegate = self
    }
    
    func connect(handler: @escaping (Error?) -> Void) {
        if channel.state.isConnecting {
            handler(SoraError.connectionBusy(reason:
                "WebSocketChannel is already connected"))
            return
        }
        
        Logger.debug(type: .webSocketChannel, message: "try connecting")
        state = .connecting
        onConnect = handler
        nativeChannel.open()
    }
    
    func disconnect(error: Error?) {
        switch state {
        case .disconnecting, .disconnected:
            break
            
        default:
            Logger.debug(type: .webSocketChannel, message: "try disconnecting")
            if error != nil {
                Logger.debug(type: .webSocketChannel,
                             message: "error: \(error!.localizedDescription)")
            }
            
            state = .disconnecting
            nativeChannel.close()
            state = .disconnected
            
            Logger.debug(type: .webSocketChannel, message: "call onDisconnect")
            channel.internalHandlers.onDisconnect?(error)
            channel.handlers.onDisconnect?(error)
            
            if onConnect != nil {
                Logger.debug(type: .webSocketChannel, message: "call connect(handler:) handler")
                onConnect!(error)
                onConnect = nil
            }
            
            Logger.debug(type: .webSocketChannel, message: "did disconnect")
        }
    }
    
    func send(message: WebSocketMessage) {
        var nativeMsg: Any!
        switch message {
        case .text(let text):
            Logger.debug(type: .webSocketChannel, message: text)
            nativeMsg = text
        case .binary(let data):
            Logger.debug(type: .webSocketChannel, message: "\(data)")
            nativeMsg = data
        }
        nativeChannel.send(nativeMsg)
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        Logger.debug(type: .webSocketChannel, message: "connected")
        state = .connected
        if onConnect != nil {
            Logger.debug(type: .webSocketChannel, message: "call connect(handler:) handler")
            onConnect!(nil)
            onConnect = nil
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!,
                   didCloseWithCode code: Int,
                   reason: String?,
                   wasClean: Bool) {
        Logger.debug(type: .webSocketChannel,
                  message: "closed with code \(code) \(reason ?? "")")
        if code != SRStatusCodeNormal.rawValue {
            let statusCode = WebSocketStatusCode(rawValue: code)
            let error = SoraError.webSocketClosed(statusCode: statusCode,
                                                  reason: reason)
            disconnect(error: error)
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        Logger.error(type: .webSocketChannel,
                     message: "failed (\(error.localizedDescription))")
        disconnect(error: SoraError.webSocketError(error))
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        Logger.debug(type: .webSocketChannel, message: "receive message")
        Logger.debug(type: .webSocketChannel, message: "\(message!)")
        var newMessage: WebSocketMessage?
        if let text = message as? String {
            newMessage = .text(text)
        } else if let data = message as? Data {
            newMessage = .binary(data)
        }
        if let message = newMessage {
            Logger.debug(type: .webSocketChannel, message: "call onReceive")
            channel.internalHandlers.onReceive?(message)
            channel.handlers.onReceive?(message)
        } else {
            Logger.debug(type: .webSocketChannel,
                      message: "received message is not string or binary (discarded)")
            // discard
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        Logger.debug(type: .webSocketChannel, message: "receive poing payload")
        Logger.debug(type: .webSocketChannel, message: "\(pongPayload!)")
        Logger.debug(type: .webSocketChannel, message: "call onPongHandler")
        channel.internalHandlers.onPong?(pongPayload)
        channel.handlers.onPong?(pongPayload)
    }
    
    func webSocketShouldConvertTextFrame(toString webSocket: SRWebSocket!) -> Bool {
        return true
    }
    
}
