# flutter_local_notifications: release(R8) 빌드에서 Gson 제네릭 타입이 지워져
# ScheduledNotificationReceiver 가 "Missing type parameter" 로 크래시하는 문제 방지.
# https://pub.dev/packages/flutter_local_notifications (Release build notes)

-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson (직렬화 타입 정보 보존)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses, EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# 플러그인이 리플렉션으로 복원하는 모델 클래스 보존
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
