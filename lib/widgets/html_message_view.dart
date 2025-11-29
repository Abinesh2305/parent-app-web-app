import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlMessageView extends StatefulWidget {
  final String html;

  const HtmlMessageView({super.key, required this.html});

  @override
  State<HtmlMessageView> createState() => _HtmlMessageViewState();
}

class _HtmlMessageViewState extends State<HtmlMessageView> {
  double contentHeight = 50;

  @override
  Widget build(BuildContext context) {
    final clean = widget.html
        .replaceAll(RegExp(r'<figure[^>]*>'), '')
        .replaceAll('</figure>', '');

    return SizedBox(
      height: contentHeight,
      child: InAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            transparentBackground: true, // important
          ),
        ),
        initialData: InAppWebViewInitialData(
          data: """
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body {
                  margin: 0;
                  padding: 0;
                  background: transparent;  /* transparent background */
                }
                table {
                  width: 100%;
                  border-collapse: collapse;
                  background: transparent;   /* transparent table */
                }
                td, th {
                  border: 1px solid #777;
                  padding: 6px;
                  font-size: 14px;
                  background: transparent;   /* transparent cells */
                }
              </style>
            </head>
            <body>
              <div id="content">$clean</div>
              <script>
                window.onload = function() {
                  var height = document.getElementById("content").scrollHeight;
                  window.flutter_inappwebview.callHandler("contentHeight", height);
                };
              </script>
            </body>
            </html>
          """,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: "contentHeight",
            callback: (args) {
              double newHeight = (args.first as num).toDouble() + 10;
              if (mounted) {
                setState(() {
                  contentHeight = newHeight;
                });
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
