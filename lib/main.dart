import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FocusNode _focusNode = FocusNode();
  WebViewController _webViewController;
  TextEditingController _textController;
  bool _isLoading = true;
  Size _deviceSize;

  @override
  Widget build(BuildContext context) {
    _deviceSize = MediaQuery.of(context).size;
    // handle the backbutton behaviour inside the webview
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dart Packages'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: _deviceSize.width,
              height: _deviceSize.height,
              child: Center(
                child: Stack(
                  children: <Widget>[
                    // Creating a TextField hidden behind the WebView and adding the input to the Websites input field using Javascript
                    Container(
                      height: 50,
                      width: _deviceSize.width,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _textController,
                        onSubmitted: (_) {
                          _webViewController.evaluateJavascript('''
                            if (input != null) {
                              input.submit();
                            }''');
                          _focusNode.unfocus();
                        },
                        onChanged: (input) {
                          _webViewController.evaluateJavascript('''
                            if (input != null) {
                              input.elements.q.value = '$input';
                            }''');
                        },
                      ),
                    ),
                    Container(
                      height: _deviceSize.height,
                      child: WebView(
                        initialUrl: 'https://pub.dartlang.org/packages/',
                        gestureRecognizers: Set()
                          ..add(
                            Factory<VerticalDragGestureRecognizer>(
                              () => VerticalDragGestureRecognizer(),
                            ),
                          ),
                        navigationDelegate: (_) {
                          _focusNode.unfocus();
                          setState(
                            () => _isLoading = true,
                          );
                          return NavigationDecision.navigate;
                        },
                        // nothing works without unrestricted JavascriptMode
                        javascriptMode: JavascriptMode.unrestricted,
                        javascriptChannels: Set.from(
                          [
                            // Listening for Javascript messages to get Notified of Focuschanges and the current input Value of the Textfield.
                            JavascriptChannel(
                              name: 'Focus',
                              // get notified of focus changes on the input field and open/close the Keyboard.
                              onMessageReceived: (JavascriptMessage focus) {
                                print(focus.message);
                                if (focus.message == 'focus') {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNode);
                                } else if (focus.message == 'focusout') {
                                  _focusNode.unfocus();
                                }
                              },
                            ),
                            JavascriptChannel(
                              name: 'InputValue',
                              // set the value of the native input field to the one on the website to always make sure they have the same input.
                              onMessageReceived: (JavascriptMessage value) {
                                _textController.value =
                                    TextEditingValue(text: value.toString());
                              },
                            )
                          ],
                        ),
                        onWebViewCreated: (controller) =>
                            _webViewController = controller,
                        onPageFinished: (_) {
                          /* 
                                if you have control over the Website you can set your own ids which is much saver than the method
                                used in this example which could break due to changes on the website. But as long as you're able 
                                to find the Input elements you can use this approach.
                              */
                          _webViewController.evaluateJavascript('''
                            inputs = document.getElementsByClassName('search-bar');
                            header = document.getElementsByClassName('site-header');
                            header[0].style.display = 'none';
                            buttons = document.getElementsByClassName('icon');
                            buttons[0].focus();
                            if (inputs != null) {
                              input = inputs[0];
                              console.log('HEEEEEEEEEEEEEEYYYYYYYYY');
                              InputValue.postMessage(input.value);
                              input.addEventListener('focus', (_) => {
                                console.log('focus');
                                Focus.postMessage('focus');
                              }, true);
                              input.addEventListener('focusout', (_) => {
                                console.log('unfocus');
                                Focus.postMessage('focusout');
                              }, true)
                            }
                            ''');
                          setState(
                            () => _isLoading = false,
                          );
                        },
                      ),
                    ),
                    // overlay to show ProgressIndicator while loading.
                    _isLoading
                        ? Container(
                            width: _deviceSize.width,
                            height: _deviceSize.height,
                            color: Colors.white,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Container()
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
