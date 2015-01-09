//
//  Foundation-Utility.m

@implementation NSDictionary (Utility)

- (id)safeObjectForKey:(id)key
{
    id object = [self objectForKey:key];
    if (object == [NSNull null]) {
        object = nil;
    }
    return object;
}

- (id)safeObjectForKey:(id)key ofClass:(Class)class
{
    id object = [self objectForKey:key];
    if (![object isKindOfClass:class]) {
        object = nil;
    }
    return object;
}

@end

@implementation NSMutableDictionary (Utility)

- (void)setObjectOrNil:(id)object forKey:(id)key
{
    if (object) {
        [self setObject:object forKey:key];
    }
}

@end
