// IADefine.h

#define IAFWLocalizedString(_key_) NSLocalizedStringFromTable(_key_,@"IAFWLocalizedString",nil)

#define TH_Ko (1000ULL)
#define TH_Mo (1000ULL*TH_Ko)
#define TH_Go (1000ULL*TH_Mo)
#define TH_To (1000ULL*TH_Go)
#define TH_Po (1000ULL*TH_To)

#ifdef __LP64__
#define CGFloatFloor(_value_)		floor(_value_)
#define CGFloatCeil(_value_)		ceil(_value_)
#define CGFloatRint(_value_)		rint(_value_)
#else
#error 64BITS_NOT_SUPPORTED
#endif

#define THFillRectWithColor(_nsrect_,_nscolor_)	{ [(_nscolor_) set]; [NSBezierPath fillRect:(_nsrect_)]; }
#define THFillRectOrange(_nsrect_)	THFillRectWithColor((_nsrect_),[NSColor orangeColor])

#define TH_RGBCOLOR(_red_,_green_,_blue_)						TH_RGBACOLOR(_red_,_green_,_blue_,1.0)
#define TH_RGBACOLOR(_red_,_green_,_blue_,_alpha_)		[NSColor colorWithDeviceRed:((CGFloat)(_red_))/255.0 green:((CGFloat)(_green_))/255.0 blue:((CGFloat)(_blue_))/255.0 alpha:(CGFloat)(_alpha_)]
