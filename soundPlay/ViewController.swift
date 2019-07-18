//
//  ViewController.swift
//  soundPlay
//
//  Created by Takdanai Jirawanichkul on 17/7/2562 BE.
//  Copyright © 2562 Takdanai Jirawanichkul. All rights reserved.
//
import UIKit
import FilesProvider
import AVFoundation


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}


class ViewController: UIViewController, FileProviderDelegate {    
    
    // FTP Setting
    let server: URL = URL(string: "ftp://192.168.1.10")!
    let username = "admin"
    let password = ""

    
    // Create File Provider
    let documentsProvider = LocalFileProvider()
    var ftpFileProvider : FTPFileProvider?

    var recordingSession: AVAudioSession!
    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FTP & Local File Setup
        ftpFileProvider?.delegate = self as FileProviderDelegate
        documentsProvider.delegate = self as FileProviderDelegate
        
        let credential = URLCredential(user: username, password: password, persistence: .permanent)
        ftpFileProvider = FTPFileProvider(baseURL: server, passive: true, credential: credential, cache: nil)
        
        // Uncomment and can see list file in console
        // getLocalFileList()
        // getFTPFileList()
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record
                    }
                }
            }
        } catch {
            // failed to record!
        }
    
    }
    
    
    // How to copy file in FTP
    func copyFTP(){
        ftpFileProvider?.copyItem(path: "example.txt", to: "example2.txt",overwrite: false, completionHandler: nil)
    }
   
    // How to delete file in FTP
    func deleteFTP(){
        ftpFileProvider?.removeItem(path: "example2.txt", completionHandler: nil)
    }
    
    func getFTPFileList(){
        ftpFileProvider?.contentsOfDirectory(path: "/", completionHandler: { (contents, error) in
            //print(error ?? "No Error")
            for file in contents {
                print("Name: \(file.name)")
                print("Size: \(file.size)")
                print("Creation Date: \(String(describing: file.creationDate))")
                print("Modification Date: \(String(describing: file.modifiedDate))")
            }
        })
    }
    
    func getLocalFileList(){
        documentsProvider.contentsOfDirectory(path: "/", completionHandler: { (contents, error) in
            //print(error ?? "No Error")
            for file in contents {
                print("Name: \(file.name)")
                print("Size: \(file.size)")
                print("Creation Date: \(String(describing: file.creationDate))")
                print("Modification Date: \(String(describing: file.modifiedDate))")
            }
        })
        
    }
    
    
    // Download Record file from FTP Server
    func downloadFTPFile(){
        // Remove file it first
        documentsProvider.removeItem(path: "playback.m4a", completionHandler: nil)
        
        let localFileURL = getDocumentsDirectory().appendingPathComponent("playback.m4a")
        ftpFileProvider?.copyItem(path: "/recording.m4a", toLocalURL: localFileURL, completionHandler: nil)
    }
    
    // Send Record file to FTP Server
    func uploadRecordFile(){
        let fileURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        ftpFileProvider?.copyItem(localFile: fileURL, to: "/recording.m4a", overwrite: true, completionHandler: nil)
        
    }

    
    func loadRecordingUI() {
        recordButton.isHidden = false
        recordButton.setTitle("Tap to Record", for: .normal)
    }
    
    // MARK: - Action
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    @IBAction func playButton(_ sender: Any) {
        if audioPlayer == nil {
            startPlayback()
        } else {
            finishPlayback()
        }
    }
    @IBAction func downloadButton(_ sender: Any) {
        print("DownloadButtonPress")
       downloadFTPFile()
    }
    
    
    // MARK: - Recording
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setTitle("Tap to Stop Record", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            uploadRecordFile() // Upload to FTP server
            recordButton.setTitle("Tap to Re-record", for: .normal)
            playButton.setTitle("Play Sound", for: .normal)
            playButton.isHidden = false
        }
        else {
            recordButton.setTitle("Tap to Record", for: .normal)
            playButton.isHidden = true
            // recording failed :(
        }
    }
    
    // MARK: - Playback
    func startPlayback() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("playback.m4a")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer.delegate = self
            audioPlayer.play()
            playButton.setTitle("Stop Playback", for: .normal)
        } catch {
            //playButton.isHidden = true
            // unable to play recording!
        }
    }
    func finishPlayback() {
        audioPlayer = nil
        playButton.setTitle("Play Sound", for: .normal)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Provider
    func fileproviderSucceed(_ fileProvider: FileProviderOperations, operation: FileOperationType) {
        switch operation {
        case .copy(source: let source, destination: let dest):
            print("\(source) copied to \(dest).")
        case .remove(path: let path):
            print("\(path) has been deleted.")
        default:
            if let destination = operation.destination {
                print("\(operation.actionDescription) from \(operation.source) to \(destination) succeed.")
            } else {
                print("\(operation.actionDescription) on \(operation.source) succeed.")
            }
        }
    }
    
    func fileproviderFailed(_ fileProvider: FileProviderOperations, operation: FileOperationType, error: Error) {
        switch operation {
        case .copy(source: let source, destination: let dest):
            print("copying \(source) to \(dest) has been failed.")
        case .remove:
            print("file can't be deleted.")
        default:
            if let destination = operation.destination {
                print("\(operation.actionDescription) from \(operation.source) to \(destination) failed.")
            } else {
                print("\(operation.actionDescription) on \(operation.source) failed.")
            }
        }
    }
    
    func fileproviderProgress(_ fileProvider: FileProviderOperations, operation: FileOperationType, progress: Float) {
        switch operation {
        case .copy(source: let source, destination: let dest) where dest.hasPrefix("file://"):
            print("Downloading \(source) to \((dest as NSString).lastPathComponent): \(progress * 100) completed.")
        case .copy(source: let source, destination: let dest) where source.hasPrefix("file://"):
            print("Uploading \((source as NSString).lastPathComponent) to \(dest): \(progress * 100) completed.")
        case .copy(source: let source, destination: let dest):
            print("Copy \(source) to \(dest): \(progress * 100) completed.")
        default:
            break
        }
    }
}

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
}

extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishPlayback()
    }
}
