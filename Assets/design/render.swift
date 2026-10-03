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
let background=load("design/assets/broadcast-background.png")
let icon=load("IMG_4187.jpg")
icon.size = NSSize(width:1206,height:2388)
func drawText(_ value:String,x:CGFloat,y:CGFloat,size:CGFloat,hex:String="f6f7fb",font:String="AvenirNext-Bold",spacing:CGFloat = -2) {
    let str=NSAttributedString(string:value,attributes:[.font:NSFont(name:font,size:size)!, .foregroundColor:color(hex),.kern:spacing])
    let s=str.size()
    str.draw(at:CGPoint(x:x,y:H-y-s.height))
}
func roundRect(_ r:CGRect,_ radius:CGFloat,fill:NSColor,stroke:NSColor?=nil,width:CGFloat=1){
    let p=NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius)
    fill.setFill();p.fill()
    if let stroke=stroke {stroke.setStroke();p.lineWidth=width;p.stroke()}
}
func screen(_ img:NSImage,x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,offset:CGFloat=0,radius:CGFloat=70,rotation:CGFloat=0){
    NSGraphicsContext.saveGraphicsState()
    if rotation != 0 {
        let transform=AffineTransform(translationByX:x+width/2,byY:H-y-height/2)
        (transform as NSAffineTransform).concat()
        let r=NSAffineTransform();r.rotate(byDegrees:rotation);r.concat()
        let t=NSAffineTransform();t.translateX(by:-(x+width/2),yBy:-(H-y-height/2));t.concat()
    }
    let r=rect(x,y,width,height)
    let shadow=NSShadow();shadow.shadowColor=NSColor.black.withAlphaComponent(0.8);shadow.shadowBlurRadius=70;shadow.shadowOffset=NSSize(width:0,height:-25);shadow.set()
    roundRect(r.insetBy(dx:-13,dy:-13),radius+13,fill:color("10141e"),stroke:color("353c4b"),width:3)
    let noShadow=NSShadow();noShadow.shadowColor = .clear;noShadow.set()
    let clip=NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius);clip.addClip()
    color("000000").setFill();r.fill()
    let ih=width*img.size.height/img.size.width
    img.draw(in:rect(x,y-offset,width,ih),from:.zero,operation:.sourceOver,fraction:1)
    color("666d7c").setStroke();clip.lineWidth=3;clip.stroke()
    NSGraphicsContext.restoreGraphicsState()
}
struct Spec {
    let name:String,accent:String,kicker:String,lines:[String],subtitle:String,image:String,type:String,size:CGFloat
    init(_ name:String,_ accent:String,_ kicker:String,_ lines:[String],_ subtitle:String,_ image:String,_ type:String="",_ size:CGFloat=112){self.name=name;self.accent=accent;self.kicker=kicker;self.lines=lines;self.subtitle=subtitle;self.image=image;self.type=type;self.size=size}
}
let specs=[
 Spec("01-discover","ff9c45","YOUR PODCASTS. ON AIR.",["Your next","great listen."],"Discover shows. Find your frequency.","IMG_4181.PNG"),
 Spec("02-favorites","ea53f7","FAVORITES & PRESETS",["Your favorites.","Front and center."],"Keep the shows you love close.","IMG_4182.PNG","",102),
 Spec("03-player","25a9ff","NOW PLAYING",["Press play.","Tune in."],"Scrub, skip, and settle into a good episode.","IMG_4185.PNG","player",118),
 Spec("04-mini-player","25a9ff","THE MINI PLAYER",["Keep browsing.","Keep listening."],"Your playback controls stay within reach.","IMG_4186.PNG","",106),
 Spec("05-history","ea53f7","YOUR BROADCAST LOG",["Good listens.","Easy to find."],"Revisit your recently played episodes.","IMG_4183.PNG"),
 Spec("06-episode-details","ea53f7","EPISODE DETAILS",["A little more","to the story."],"Read the show notes. Resume when ready.","IMG_4184.PNG","detail"),
 Spec("07-on-air","ff9c45","MAKE IT YOUR MOMENT",["Good shows.","Great company."],"Make time for your next favorite podcast.","IMG_4181.PNG","final",108)
]
func save(_ context:CGContext,_ path:String){
    let dest=CGImageDestinationCreateWithURL(root.appendingPathComponent(path) as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(dest,context.makeImage()!,nil)
    precondition(CGImageDestinationFinalize(dest))
}
for (i,s) in specs.enumerated(){
    let context=CGContext(data:nil,width:Int(W),height:Int(H),bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:false)
    background.draw(in:rect(0,0,W,H))
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect:rect(86,86,72,72),xRadius:18,yRadius:18).addClip()
    icon.draw(in:rect(86,86,72,72),from:CGRect(x:459,y:2388-1006-294,width:294,height:294),operation:.sourceOver,fraction:1)
    NSGraphicsContext.restoreGraphicsState()
    drawText("On Air",x:180,y:92,size:34,spacing:1)
    for (j,v) in [16,30,40,22,34,13].enumerated(){roundRect(rect(1070+CGFloat(j)*15,125-CGFloat(v)/2,7,CGFloat(v)),4,fill:color(s.accent))}
    drawText(s.kicker,x:86,y:231,size:29,hex:s.accent,font:"AvenirNextCondensed-DemiBold",spacing:6)
    drawText(s.lines[0],x:80,y:286,size:s.size,spacing:-5)
    drawText(s.lines[1],x:80,y:286+s.size*1.03,size:s.size,hex:s.accent,spacing:-5)
    drawText(s.subtitle,x:86,y:286+s.size*2.06+37,size:37,hex:"b8c0d1",font:"AvenirNext-Medium",spacing:-0.6)
    let img=load(s.image)
    switch s.type {
    case "player":screen(img,x:191,y:840,width:860,height:1615,offset:121)
    case "detail":
        color("343847").setStroke()
        for y:CGFloat in [790,906] {let p=NSBezierPath();p.move(to:CGPoint(x:86,y:H-y));p.line(to:CGPoint(x:1156,y:H-y));p.lineWidth=1;p.stroke()}
        for (j,t) in ["SHOW NOTES","PROGRESS","RESUME"].enumerated(){let x=86+CGFloat(j)*377;drawText(String(format:"%02d",j+1),x:x,y:828,size:27,hex:s.accent,font:"AvenirNextCondensed-DemiBold",spacing:2);drawText(t,x:x+53,y:828,size:27,hex:"b9c1d3",font:"AvenirNextCondensed-DemiBold",spacing:3)}
        screen(img,x:67,y:1090,width:1108,height:1240,offset:1148,radius:108)
    case "final":
        drawText("DISCOVER  /  SAVE  /  LISTEN",x:86,y:698,size:31,hex:"d6dce7",font:"AvenirNextCondensed-DemiBold",spacing:3)
        screen(img,x:-67,y:1100,width:760,height:1650,radius:65,rotation:9)
        screen(load("IMG_4185.PNG"),x:612,y:970,width:760,height:1425,offset:106,radius:65,rotation:-10)
    default:screen(img,x:191,y:740,width:860,height:1870)
    }
    if s.type != "final" {drawText(String(format:"%02d / 07",i+1),x:87,y:2604,size:22,hex:"7a8398",font:"AvenirNextCondensed-Medium",spacing:4)}
    save(context,"AppStore-1242x2688/\(s.name).png")
    NSGraphicsContext.restoreGraphicsState()
    print("Rendered \(s.name): 1242 × 2688 RGB")
}
let pw=2354,ph=732
let preview=CGContext(data:nil,width:pw,height:ph,bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
preview.setFillColor(color("0b1020").cgColor);preview.fill(CGRect(x:0,y:0,width:pw,height:ph))
for (i,s) in specs.enumerated(){let src=CGImageSourceCreateWithURL(root.appendingPathComponent("AppStore-1242x2688/\(s.name).png") as CFURL,nil)!;let im=CGImageSourceCreateImageAtIndex(src,0,nil)!;preview.draw(im,in:CGRect(x:30+Double(i)*330.5,y:30,width:310.5,height:672))}
save(preview,"Preview.png")
