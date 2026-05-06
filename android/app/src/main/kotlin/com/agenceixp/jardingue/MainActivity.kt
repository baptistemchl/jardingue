package com.agenceixp.jardingue

import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        try {
            super.onStart()
        } catch (e: RuntimeException) {
            if (isFlutterNativeLibMissing(e)) {
                Log.e(TAG, "libflutter.so missing — corrupted Play Store install", e)
                showCorruptedInstallDialog()
                return
            }
            throw e
        }
    }

    private fun isFlutterNativeLibMissing(throwable: Throwable): Boolean {
        var t: Throwable? = throwable
        while (t != null) {
            if (t.message?.contains("libflutter.so") == true) return true
            t = t.cause
        }
        return false
    }

    private fun showCorruptedInstallDialog() {
        if (isFinishing || isDestroyed) return
        AlertDialog.Builder(this)
            .setTitle("Installation incomplète")
            .setMessage(
                "L'application n'a pas été installée correctement par le Play Store.\n\n" +
                    "Veuillez la désinstaller puis la réinstaller depuis le Play Store pour résoudre le problème.",
            )
            .setCancelable(false)
            .setPositiveButton("Ouvrir le Play Store") { _, _ ->
                openPlayStore()
                finish()
            }
            .setNegativeButton("Fermer") { _, _ -> finish() }
            .show()
    }

    private fun openPlayStore() {
        val marketUri = Uri.parse("market://details?id=$packageName")
        val webUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
        try {
            startActivity(
                Intent(Intent.ACTION_VIEW, marketUri)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (_: ActivityNotFoundException) {
            startActivity(
                Intent(Intent.ACTION_VIEW, webUri)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    private companion object {
        const val TAG = "MainActivity"
    }
}
