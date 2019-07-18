# PlayRecordSoundwithFTP_Swift

This project is an example of using Swift language for record and playback with FTP Server

Description
This app can use for 
1. Record your voice message and then this app will send file to save in FTP Server.
2. Play your voice message by download file from FTP server and play
  ( * Build version : You need to press download button to download new voice message every times )  
                      

How to use
1. Set up FTP setting in Viewcontroller.swift file
2. See the function and change some value what ever you need.


Using library: FilesProvider 
  To manage Local file and FTP file Server.
  
  'pod install'  before use 
  
You can see more information about this library > https://github.com/amosavian/FileProvider
  
  
This app just simple use the FilesProvider library integrate with AVFoundation ( To play/record sound )
  STILL HAVE MANY BUG 
  
