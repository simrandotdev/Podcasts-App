import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let W: CGFloat = 1242, H: CGFloat = 2688
let space = CGColorSpace(name: CGColorSpace.sRGB)!
func color(_ hex: String) -> NSColor {
    let v = UInt32(hex, radix:16)!
    return NSColor(srgbRed:CGFloat((v>>16)&255)/255,green:CGFloat((v>>8)&255)/255,blue:CGFloat(v&255)/255,alpha:1)
}
func rect(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat) -> CGRect {CGRect(x:x,y:H-y-h,width:w,height:h)}
func load(_ file:String)->NSImage {NSImage(contentsOf:root.appendingPathComponent(file))!}
let icon=load("IMG_4187.jpg")
icon.size = NSSize(width:1206,height:2388)
let iphoneFrame=load("design-minimal/assets/iphone-16-pro-natural-titanium.png")
func drawText(_ value:String,x:CGFloat,y:CGFloat,size:CGFloat,hex:String="171717",font:String="AvenirNext-DemiBold",spacing:CGFloat = -2) {
    let str=NSAttributedString(string:value,attributes:[.font:NSFont(name:font,size:size)!, .foregroundColor:color(hex),.kern:spacing])
    let s=str.size()
    str.draw(at:CGPoint(x:x,y:H-y-s.height))
}
func centered(_ value:String,y:CGFloat,size:CGFloat,hex:String="171717",font:String="AvenirNext-DemiBold",spacing:CGFloat = -2) {
    let str=NSAttributedString(string:value,attributes:[.font:NSFont(name:font,size:size)!, .foregroundColor:color(hex),.kern:spacing])
    let s=str.size()
    precondition(s.width < 1100,"Text overflows: \(value)")
    str.draw(at:CGPoint(x:(W-s.width)/2,y:H-y-s.height))
}
func roundRect(_ r:CGRect,_ radius:CGFloat,fill:NSColor,stroke:NSColor?=nil,width:CGFloat=1){
    let p=NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius)
    fill.setFill();p.fill()
    if let stroke=stroke {stroke.setStroke();p.lineWidth=width;p.stroke()}
}
// iPhone 16 Pro PNG: 450 × 920, display at (24,23), 402 × 874.
// The 1206 × 2622 source captures match this display exactly at 3×.
func screen(_ img:NSImage,x:CGFloat,y:CGFloat,width:CGFloat){
    let scale=width/450
    let height=920*scale
    precondition(x >= 0 && x+width <= W && y+height <= H)
    let display=rect(x+24*scale,y+23*scale,402*scale,874*scale)
    NSGraphicsContext.saveGraphicsState()
    let clip=NSBezierPath(roundedRect:display,xRadius:50*scale,yRadius:50*scale)
    clip.addClip()
    img.draw(in:display,from:.zero,operation:.sourceOver,fraction:1)
    NSGraphicsContext.restoreGraphicsState()
    iphoneFrame.draw(in:rect(x,y,width,height),from:.zero,operation:.sourceOver,fraction:1)
}
struct Spec {
    let name:String,accent:String,kicker:String,lines:[String],subtitle:String,image:String,type:String,size:CGFloat
    init(_ name:String,_ accent:String,_ kicker:String,_ lines:[String],_ subtitle:String,_ image:String,_ type:String="",_ size:CGFloat=112){self.name=name;self.accent=accent;self.kicker=kicker;self.lines=lines;self.subtitle=subtitle;self.image=image;self.type=type;self.size=size}
}
let specs=[
 Spec("01-discover","ff9c45","",["Your next","great listen."],"Discover your next favorite podcast.","IMG_4181.PNG","",104),
 Spec("02-favorites","ea53f7","",["Keep your","favorites close."],"Your shows, saved in one place.","IMG_4182.PNG","",104),
 Spec("03-player","25a9ff","",["Just press","play."],"Simple controls. More listening.","IMG_4185.PNG","player",104),
 Spec("04-mini-player","25a9ff","",["Browse on.","Listen on."],"Playback stays within reach.","IMG_4186.PNG","",104),
 Spec("05-history","ea53f7","",["Back to a","good listen."],"Find your recently played episodes.","IMG_4183.PNG","",104),
 Spec("06-episode-details","ea53f7","",["More to","the story."],"Show notes, progress, and a place to resume.","IMG_4184.PNG","detail",104),
 Spec("07-on-air","ff9c45","",["Your podcasts.","Your moment."],"Discover. Save. Listen.","IMG_4181.PNG","final",104)
]
func save(_ context:CGContext,_ path:String){
    let dest=CGImageDestinationCreateWithURL(root.appendingPathComponent(path) as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(dest,context.makeImage()!,nil)
    precondition(CGImageDestinationFinalize(dest))
}
for s in specs {
    let context=CGContext(data:nil,width:Int(W),height:Int(H),bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:false)
    color("f5f3ef").setFill();rect(0,0,W,H).fill()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect:rect(526,112,52,52),xRadius:13,yRadius:13).addClip()
    icon.draw(in:rect(526,112,52,52),from:CGRect(x:459,y:2388-1006-294,width:294,height:294),operation:.sourceOver,fraction:1)
    NSGraphicsContext.restoreGraphicsState()
    drawText("On Air",x:598,y:116,size:33,spacing:-0.5)
    centered(s.lines[0],y:250,size:s.size,spacing:-4)
    centered(s.lines[1],y:358,size:s.size,spacing:-4)
    centered(s.subtitle,y:524,size:35,hex:"77746f",font:"AvenirNext-Regular",spacing:-0.6)
    let img=load(s.image)
    switch s.type {
    case "final":
        screen(img,x:61,y:960,width:540)
        screen(load("IMG_4185.PNG"),x:641,y:1160,width:540)
    default:screen(img,x:147,y:684,width:948)
    }
    save(context,"AppStore-Minimal-1242x2688/\(s.name).png")
    NSGraphicsContext.restoreGraphicsState()
    print("Rendered \(s.name): 1242 × 2688 RGB")
}
let pw=2354,ph=732
let preview=CGContext(data:nil,width:pw,height:ph,bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
preview.setFillColor(color("dfdcd7").cgColor);preview.fill(CGRect(x:0,y:0,width:pw,height:ph))
for (i,s) in specs.enumerated(){let src=CGImageSourceCreateWithURL(root.appendingPathComponent("AppStore-Minimal-1242x2688/\(s.name).png") as CFURL,nil)!;let im=CGImageSourceCreateImageAtIndex(src,0,nil)!;preview.draw(im,in:CGRect(x:30+Double(i)*330.5,y:30,width:310.5,height:672))}
save(preview,"Preview-Minimal.png")
