#import <Foundation/Foundation.h>

// Hack to get the private auditToken property
@interface NSXPCConnection(PrivateAuditToken)

@property (nonatomic, readonly) audit_token_t auditToken;

@end

// Interface for AuditTokenHack
@interface AuditTokenHack : NSObject

+(NSData *)getAuditTokenDataFromNSXPCConnection:(NSXPCConnection *)connection;

@end
