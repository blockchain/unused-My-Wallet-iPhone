//
//  Foundation-Utility.h
//

#import <Foundation/Foundation.h>

#pragma mark -

@interface NSDictionary (Utility)

- (id)safeObjectForKey:(id)key; 
- (id)safeObjectForKey:(id)key ofClass:(Class)class;

@end

@interface NSMutableDictionary (Utility)

- (void)setObjectOrNil:(id)object forKey:(id)key;

@end
