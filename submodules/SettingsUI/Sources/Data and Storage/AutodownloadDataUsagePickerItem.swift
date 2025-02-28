import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences
import TelegramPresentationData
import LegacyComponents
import ItemListUI

enum AutomaticDownloadDataUsage: Int {
    case low
    case medium
    case high
    case custom
    
    init(preset: MediaAutoDownloadPreset) {
        switch preset {
            case .low:
                self = .low
            case .medium:
                self = .medium
            case .high:
                self = .high
            case .custom:
                self = .custom
        }
    }
}

class AutodownloadDataUsagePickerItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let strings: PresentationStrings
    let value: AutomaticDownloadDataUsage
    let customPosition: Int?
    let enabled: Bool
    let sectionId: ItemListSectionId
    let updated: (AutomaticDownloadDataUsage) -> Void
    
    init(theme: PresentationTheme, strings: PresentationStrings, value: AutomaticDownloadDataUsage, customPosition: Int?, enabled: Bool, sectionId: ItemListSectionId, updated: @escaping (AutomaticDownloadDataUsage) -> Void) {
        self.theme = theme
        self.strings = strings
        self.value = value
        self.customPosition = customPosition
        self.enabled = enabled
        self.sectionId = sectionId
        self.updated = updated
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = AutodownloadDataUsagePickerItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? AutodownloadDataUsagePickerItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
}

private func generateKnobImage() -> UIImage? {
    return generateImage(CGSize(width: 40.0, height: 40.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setShadow(offset: CGSize(width: 0.0, height: -2.0), blur: 3.5, color: UIColor(white: 0.0, alpha: 0.35).cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 28.0, height: 28.0)))
    })
}

class AutodownloadDataUsagePickerItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    
    private let lowTextNode: TextNode
    private let mediumTextNode: TextNode
    private let highTextNode: TextNode
    private let customTextNode: TextNode
    private var sliderView: TGPhotoEditorSliderView?
    
    private var item: AutodownloadDataUsagePickerItem?
    private var layoutParams: ListViewItemLayoutParams?
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.lowTextNode = TextNode()
        self.lowTextNode.isUserInteractionEnabled = false
        self.lowTextNode.displaysAsynchronously = false
        
        self.mediumTextNode = TextNode()
        self.mediumTextNode.isUserInteractionEnabled = false
        self.mediumTextNode.displaysAsynchronously = false
        
        self.highTextNode = TextNode()
        self.highTextNode.isUserInteractionEnabled = false
        self.highTextNode.displaysAsynchronously = false
      
        self.customTextNode = TextNode()
        self.customTextNode.isUserInteractionEnabled = false
        self.customTextNode.displaysAsynchronously = false
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.lowTextNode)
        self.addSubnode(self.mediumTextNode)
        self.addSubnode(self.highTextNode)
        self.addSubnode(self.customTextNode)
    }
    
    func updateSliderView() {
        if let sliderView = self.sliderView, let item = self.item {
            sliderView.maximumValue = 2.0 + (item.customPosition != nil ? 1 : 0)
            sliderView.positionsCount = 3 + (item.customPosition != nil ? 1 : 0)
            var value = item.value.rawValue
            if let customPosition = item.customPosition {
                if case .custom = item.value {
                    value = customPosition
                } else {
                    if value >= customPosition {
                        value += 1
                    }
                }
            }
            
            sliderView.value = CGFloat(value)
            
            sliderView.isUserInteractionEnabled = item.enabled
            sliderView.alpha = item.enabled ? 1.0 : 0.4
            sliderView.layer.allowsGroupOpacity = !item.enabled
        }
    }
    
    override func didLoad() {
        super.didLoad()
        
        let sliderView = TGPhotoEditorSliderView()
        sliderView.enablePanHandling = true
        sliderView.trackCornerRadius = 1.0
        sliderView.lineSize = 2.0
        sliderView.dotSize = 5.0
        sliderView.minimumValue = 0.0
        sliderView.maximumValue = 2.0 + (self.item?.customPosition != nil ? 1 : 0)
        sliderView.startValue = 0.0
        sliderView.disablesInteractiveTransitionGestureRecognizer = true
        sliderView.positionsCount = 3 + (self.item?.customPosition != nil ? 1 : 0)
        sliderView.useLinesForPositions = true
        if let item = self.item, let params = self.layoutParams {
            var value = item.value.rawValue
            if let customPosition = item.customPosition {
                if case .custom = item.value {
                    value = customPosition
                } else {
                    if value >= customPosition {
                        value += 1
                    }
                }
            }
            
            sliderView.value = CGFloat(value)
            sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
            sliderView.backColor = item.theme.list.disclosureArrowColor
            sliderView.startColor = item.theme.list.disclosureArrowColor
            sliderView.trackColor = item.theme.list.itemAccentColor
            sliderView.knobImage = generateKnobImage()
            
            sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 15.0, y: 37.0), size: CGSize(width: params.width - params.leftInset - params.rightInset - 15.0 * 2.0, height: 44.0))
            sliderView.hitTestEdgeInsets = UIEdgeInsets(top: -sliderView.frame.minX, left: 0.0, bottom: 0.0, right: -sliderView.frame.minX)
        }
        self.view.addSubview(sliderView)
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.sliderView = sliderView
        
        self.updateSliderView()
    }
    
    func asyncLayout() -> (_ item: AutodownloadDataUsagePickerItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentItem = self.item
        let makeLowTextLayout = TextNode.asyncLayout(self.lowTextNode)
        let makeMediumTextLayout = TextNode.asyncLayout(self.mediumTextNode)
        let makeHighTextLayout = TextNode.asyncLayout(self.highTextNode)
        let makeCustomTextLayout = TextNode.asyncLayout(self.customTextNode)
        
        return { item, params, neighbors in
            var themeUpdated = false
            if currentItem?.theme !== item.theme {
                themeUpdated = true
            }
            
            let contentSize: CGSize
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel
            
            let (lowTextLayout, lowTextApply) = makeLowTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.strings.AutoDownloadSettings_DataUsageLow, font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))

            let (mediumTextLayout, mediumTextApply) = makeMediumTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.strings.AutoDownloadSettings_DataUsageMedium, font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (highTextLayout, highTextApply) = makeHighTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.strings.AutoDownloadSettings_DataUsageHigh, font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (customTextLayout, customTextApply) = makeCustomTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.strings.AutoDownloadSettings_DataUsageCustom, font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            contentSize = CGSize(width: params.width, height: 88.0)
            insets = itemListNeighborsGroupedInsets(neighbors)
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    strongSelf.layoutParams = params
                    
                    strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                    strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    switch neighbors.top {
                    case .sameSection(false):
                        strongSelf.topStripeNode.isHidden = true
                    default:
                        strongSelf.topStripeNode.isHidden = false
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                    case .sameSection(false):
                        bottomStripeInset = 0.0 //params.leftInset + 16.0
                        bottomStripeOffset = -separatorHeight
                    default:
                        bottomStripeInset = 0.0
                        bottomStripeOffset = 0.0
                    }
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                    
                    let _ = lowTextApply()
                    let _ = mediumTextApply()
                    let _ = highTextApply()
                    let _ = customTextApply()
                    
                    var textNodes: [(TextNode, CGSize)] = [(strongSelf.lowTextNode, lowTextLayout.size),
                                                           (strongSelf.mediumTextNode, mediumTextLayout.size),
                                                           (strongSelf.highTextNode, highTextLayout.size)]
                    if let customPosition = item.customPosition {
                        textNodes.insert((strongSelf.customTextNode, customTextLayout.size), at: customPosition)
                    }
                    
                    let delta = (params.width - params.leftInset - params.rightInset - 18.0 * 2.0) / CGFloat(textNodes.count - 1)
                    for i in 0 ..< textNodes.count {
                        let (textNode, textSize) = textNodes[i]
                        
                        var position = params.leftInset + 18.0 + delta * CGFloat(i)
                        if i == textNodes.count - 1 {
                            position -= textSize.width
                        } else if i > 0 {
                            position -= textSize.width / 2.0
                        }
                        
                        textNode.frame = CGRect(origin: CGPoint(x: position, y: 15.0), size: textSize)
                    }
                    
                    if let sliderView = strongSelf.sliderView {
                        if themeUpdated {
                            sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                            sliderView.backColor = item.theme.list.disclosureArrowColor
                            sliderView.trackColor = item.theme.list.itemAccentColor
                            sliderView.knobImage = generateKnobImage()
                        }
                        
                        sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 15.0, y: 37.0), size: CGSize(width: params.width - params.leftInset - params.rightInset - 15.0 * 2.0, height: 44.0))
                        sliderView.hitTestEdgeInsets = UIEdgeInsets(top: -sliderView.frame.minX, left: 0.0, bottom: 0.0, right: -sliderView.frame.minX)
                        
                        strongSelf.updateSliderView()
                    }
                }
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    @objc func sliderValueChanged() {
        guard let sliderView = self.sliderView else {
            return
        }
        
        let position = Int(sliderView.value)
        var value: AutomaticDownloadDataUsage?
        
        if let customPosition = self.item?.customPosition {
            if position == customPosition {
                value = .custom
            } else {
                value = AutomaticDownloadDataUsage(rawValue: position > customPosition ? (position - 1) : position)
            }
        } else {
            value = AutomaticDownloadDataUsage(rawValue: position)
        }
        
        if let value = value {
            self.item?.updated(value)
        }
    }
}

