#import <objc/runtime.h>

// A macro for defining instance variables at runtime from an Objective-C category

#ifndef ASSOCIATED_STORAGE_PROPERTY_IMP
#define THREE_WAY_PASTER_INNER(a, b, c) a ## b ## c
#define THREE_WAY_PASTER(x,y,z) THREE_WAY_PASTER_INNER(x,y,z)
 
#define ASSOCIATED_STORAGE_PROPERTY_IMP(type, setter, getter, policy) \
static char THREE_WAY_PASTER(__ASSOCIATED_STORAGE_KEY_, getter, __LINE__); \
\
- (type)getter {\
    return objc_getAssociatedObject(self, &THREE_WAY_PASTER(__ASSOCIATED_STORAGE_KEY_, getter,__LINE__) );\
} \
\
- (void)setter: (type)value {\
    objc_setAssociatedObject(self, &THREE_WAY_PASTER(__ASSOCIATED_STORAGE_KEY_, getter,__LINE__) , value, policy);\
} 
#endif