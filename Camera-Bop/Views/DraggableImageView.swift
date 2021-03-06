//
//  DraggableImageView.swift
//  Continuity-Helper
//
//  Created by LiangYi on 2020/7/7.
//

import Cocoa

class DraggableImageView: NSImageView {
    
    enum RuntimeError: Error {
        case ioError
    }
    
    var ext: ReceiveExtension!
    
    var data: Data!
    
    var title: String = "Untitle"
    
    private let dragThreshold: CGFloat = 3.0
    
    private var mouseEvent: NSEvent? = nil
    
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    var draggingImage: NSImage {
        let targetRect = self.bounds
        let image = NSImage(size: targetRect.size)
        if let imageRep = bitmapImageRepForCachingDisplay(in: targetRect) {
            cacheDisplay(in: targetRect, to: imageRep)
            image.addRepresentation(imageRep)
        }
        
        return image
    }
    
    // MARK: -Dragging
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    
    override func mouseDown(with event: NSEvent) {
        self.mouseEvent = event
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        guard let mouse = self.mouseEvent else { return }
        
        let origin = convert(mouse.locationInWindow, from: nil)
        let current = convert(event.locationInWindow, from: nil)
        
        guard abs(current.x - origin.x) > dragThreshold || abs(current.y - origin.y) > dragThreshold else { return }
        
        let provider = NSFilePromiseProvider(fileType: kUTTypeTIFF as String, delegate: self)
        provider.userInfo = data
        
        let draggingItem = NSDraggingItem(pasteboardWriter: provider)
        
        draggingItem.setDraggingFrame(self.bounds, contents: draggingImage)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return self.image != nil
    }
    
}

// MARK: -NSDraggingSource
extension DraggableImageView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return (context == .outsideApplication) ? [.copy] : []
    }
}

// MARK: -NSFilePromiseProviderDelegate
extension DraggableImageView: NSFilePromiseProviderDelegate {
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return "\(title).\(ext.rawValue)"
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            if let data = filePromiseProvider.userInfo as? Data {
                
                try data.write(to: url)
            } else {
                throw RuntimeError.ioError
            }
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }
    }
    
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return self.workQueue
    }
    
    
}
