// IADefine.h

#define IA_GREY_COLOUR(_grey_)                           IA_RGBA_COLOUR(_grey_, _grey_, _grey_, 1.0)
#define IA_RGB_COLOUR(_red_, _green_, _blue_)			 IA_RGBA_COLOUR(_red_, _green_, _blue_, 1.0)
#define IA_RGBA_COLOUR(_red_, _green_, _blue_, _alpha_)	[NSColor colorWithDeviceRed:((CGFloat)(_red_))/255.0 green:((CGFloat)(_green_))/255.0 blue:((CGFloat)(_blue_))/255.0 alpha:(CGFloat)(_alpha_)]