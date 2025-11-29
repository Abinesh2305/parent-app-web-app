import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlMessageView extends StatefulWidget {
  final String html;
  final String activeWord;

  const HtmlMessageView({
    super.key,
    required this.html,
    required this.activeWord,
  });

  @override
  State<HtmlMessageView> createState() => _HtmlMessageViewState();
}

class _HtmlMessageViewState extends State<HtmlMessageView> {
  double contentHeight = 50;
  InAppWebViewController? webController;

  @override
  void didUpdateWidget(HtmlMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeWord.isNotEmpty &&
        widget.activeWord != oldWidget.activeWord &&
        webController != null) {
      webController!.evaluateJavascript(
        source: "highlightWord('${widget.activeWord}');",
      );
    }
  }

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
            transparentBackground: true,
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
                  background: transparent;
                }
                table {
                  width: 100%;
                  border-collapse: collapse;
                  background: transparent;
                }
                td, th {
                  border: 1px solid #777;
                  padding: 6px;
                  font-size: 14px;
                  background: transparent;
                }
                mark.hl {
                  background: yellow;
                  color: black;
                  font-weight: bold;
                }
              </style>

              <script>
                function highlightWord(word) {
                  if (!word || word.trim() === "") return;

                  var content = document.getElementById("content");

                  // Remove old highlights
                  content.innerHTML = content.innerHTML.replace(/<mark class="hl">([^<]+)<\\/mark>/g, "\$1");

                  // Apply new highlight
                  var regex = new RegExp("\\\\b" + word + "\\\\b", "gi");
                  content.innerHTML = content.innerHTML.replace(regex, '<mark class="hl">\$&</mark>');

                  // Auto scroll
                  var el = document.querySelector("mark.hl");
                  if (el) {
                    el.scrollIntoView({ behavior: "smooth", block: "center" });
                  }
                }

                window.onload = function() {
                  var h = document.getElementById("content").scrollHeight;
                  window.flutter_inappwebview.callHandler("contentHeight", h);
                };
              </script>
            </head>

            <body>
              <div id="content">$clean</div>
            </body>
            </html>
          """,
        ),
        onWebViewCreated: (controller) {
          webController = controller;

          controller.addJavaScriptHandler(
            handlerName: "contentHeight",
            callback: (args) {
              double newHeight = (args.first as num).toDouble() + 10;

              if (mounted) {
                setState(() => contentHeight = newHeight);
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
