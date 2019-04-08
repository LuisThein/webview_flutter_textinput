# webview_flutter_textinput
Example Flutter App with workaround for current webview_flutter versions (0.3.5+3) with unfocusable input fields on Android.

This example uses the ability to run Javascript inside the Webview and propagating back focus events to the Dart code in order to open the keyboard on a hidden input field, where you input the Text and set it through Javascript as the Value of the input Field on the Website. 
