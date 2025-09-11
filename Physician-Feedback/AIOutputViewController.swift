//
//  AIOutputViewController.swift
//  Physician-Feedback
//
//  Created by ChangS13 on 7/18/25.
//

import UIKit

class AIOutputViewController: UIViewController {
    private var hasGeneratedOutput = false
    var transcribedText: String?

    @IBOutlet weak var responseView: UITextView!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            guard !hasGeneratedOutput else { return }
            hasGeneratedOutput = true

            let prompt = """
            You are a medical scribe. Below is a transcript of a conversation between a patient and a doctor.

            Conversation:
            \"\(transcribedText ?? "")\"

            Based on this, generate a concise physician note summarizing the encounter.

            Return only the text of the note, without any extra commentary or output.
            Format:
            Chief Complaint:
            [Insert or leave blank]
            
            Review of Systems:
            [Insert or leave blank]
            
            History of Present Illness:
            [Insert or leave blank]
            
            Physical Exam:
            [Insert or leave blank]

            Plan:
            [Insert or leave blank]
            
            Follow-up Instructions:
            [Insert or leave blank]
            
            Medications Discussed or Prescribed:
            [Insert or leave blank]
            """

            callOpenAI(prompt: prompt) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        self.responseView.text = "No response from GPT"
                        return
                    }
                

                    self.responseView.text = response.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    
    @IBAction func backButton(_ sender: Any) {
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
}
