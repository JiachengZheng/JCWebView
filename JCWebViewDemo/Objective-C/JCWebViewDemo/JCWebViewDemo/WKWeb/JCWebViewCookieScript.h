//
//  JCWebViewCookieScript.h
//  Pods
//
//  Created by zhengjiacheng on 2017/6/2.
//
//

#ifndef JCWebViewCookieScript_h
#define JCWebViewCookieScript_h


#endif /* JCWebViewCookieScript_h */

/* 注入Cookie js脚本
*  暂时不知道HttpOnly
*  不设置不知道会不会有影响
*/
#define kInjectLocalCookieScript @"function setCookieFromApp(name, value, expires, path, domain, secure)\
{\
var argv = arguments;\
var argc = arguments.length;\
var now = new Date();\
var expires = (argc > 2) ? new Date(new Date().getTime() + parseInt(expires) * 24 * 60 * 60 * 1000) : new Date(now.getFullYear(), now.getMonth() + 1, now.getUTCDate());\
var path = (argc > 3) ? argv[3] : '/';\
var domain = (argc > 4) ? argv[4] :'';\
var secure = (argc > 5) ? argv[5] : false;\
var httpOnly = (argc > 6) ? argv[6] : false;\
document.cookie = name + '=' + value + ((expires == null) ? '' : ('; expires=' + expires.toGMTString())) + ((path == null) ? '' : ('; path=' + path)) + ((domain == null) ? '' : ('; domain=' + domain)) + ((secure == true) ? '; secure' : '');\
};\
"
