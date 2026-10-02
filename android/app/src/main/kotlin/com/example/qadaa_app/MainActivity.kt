package com.example.qadaa_app

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.qadaa_app/print"
    private var printWebView: WebView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "printHtml") {
                val title = call.argument<String>("title") ?: "المستند"
                val html = call.argument<String>("html") ?: ""
                try {
                    printHtmlContent(title, html)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PRINT_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun printHtmlContent(title: String, html: String) {
        runOnUiThread {
            val webView = WebView(this)
            printWebView = webView
            webView.settings.javaScriptEnabled = true
            webView.settings.defaultTextEncodingName = "utf-8"
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    val printManager = getSystemService(Context.PRINT_SERVICE) as? PrintManager
                    if (printManager != null) {
                        val jobName = "$title - تطبيق قضاء"
                        val printAdapter = webView.createPrintDocumentAdapter(jobName)
                        printManager.print(jobName, printAdapter, PrintAttributes.Builder().build())
                    }
                }
            }
            webView.loadDataWithBaseURL("about:blank", html, "text/html", "UTF-8", null)
        }
    }
}
