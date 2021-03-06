/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"
#import "objc/runtime.h"

static char loadOperationKey;

@implementation UIView (WebCacheOperation)

- (NSMutableDictionary *)operationDictionary {
    // 这里用关联给imageView 对象并且懒加载添加了一个 Dictionary（保存operation） 的get 方法
    // 当字典对象不存在时 新创建一个 NSMutableDictionary并且设置set方法的关联
    
    NSMutableDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
    if (operations) {
        return operations;
    }
    operations = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return operations;
}

- (void)sd_setImageLoadOperation:(id)operation forKey:(NSString *)key {
    // cancel 上一次可能正在进行的loadImg的操作
    // 这里 opertion 对象可能是单个opetion ，也可能是包含多个operation的array
    // cancel 之后将新传入的 opertion 加入到 operationDictionary中
    
    [self sd_cancelImageLoadOperationWithKey:key];
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    [operationDictionary setObject:operation forKey:key];
}

- (void)sd_cancelImageLoadOperationWithKey:(NSString *)key {
    // Cancel in progress downloader from queue
    // 根据key 去operation中查找并且cancel掉保存在 operationDictionary 中的 operation 对象 该operation 可能是NSArray或者是遵循  <SDWebImageOperation> 协议的对象类型
    // 如果是NSArray 其中保存的也是遵循了 <SDWebImageOperation> 协议的对象
    // 为什么这些对象都需要遵守 <SDWebImageOperation> 这个协议? 因为该协议声明了 -cancel 方法,既然根据key是cancel掉operation， 所以必须遵守这个协议
    // cancel 完成后将 key 从 operationDictionary 移除
    
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    id operations = [operationDictionary objectForKey:key];
    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <SDWebImageOperation> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        } else if ([operations conformsToProtocol:@protocol(SDWebImageOperation)]){
            [(id<SDWebImageOperation>) operations cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
}

- (void)sd_removeImageLoadOperationWithKey:(NSString *)key {
    
    // 根据传入的key从 operationDictionary 删除对应的operation
    
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    [operationDictionary removeObjectForKey:key];
}

@end
