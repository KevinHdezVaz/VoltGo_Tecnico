package us.voltgoTec.appc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.media.RingtoneManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Crear canales de notificación para OneSignal
        createNotificationChannels()
    }
  
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Canal para solicitudes de servicio (técnicos)
            val serviceRequestsChannel = NotificationChannel(
                "service_requests",
                "Solicitudes de Servicio",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de nuevas solicitudes de servicio"
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(false) // ✅ DESACTIVAR VIBRACIÓN
                setShowBadge(true)
                // ✅ CONFIGURAR SONIDO PERSONALIZADO (OPCIONAL)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    Notification.AUDIO_ATTRIBUTES_DEFAULT
                )
            }
            
            // Canal para actualizaciones de estado (usuarios)
            val serviceUpdatesChannel = NotificationChannel(
                "service_updates",
                "Actualizaciones de Servicio",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Actualizaciones del estado de tus servicios"
                enableLights(true)
                lightColor = Color.GREEN
                enableVibration(false) // ✅ DESACTIVAR VIBRACIÓN
                setShowBadge(true)
            }
            
            // Crear los canales
            notificationManager.createNotificationChannel(serviceRequestsChannel)
            notificationManager.createNotificationChannel(serviceUpdatesChannel)
            
            println("VoltGo: Canales de notificación creados sin vibración")
        }
    }
}