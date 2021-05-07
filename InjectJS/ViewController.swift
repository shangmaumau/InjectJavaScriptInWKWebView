//
//  ViewController.swift
//  InjectJS
//
//  Created by 尚雷勋 on 2021/5/1.
//

import UIKit

class ViewController: UIViewController {

    var btn: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        title = "VC"
        initSubViews()
    }

    func initSubViews() {

        btn = UIButton(type: .custom)
        btn?.frame = CGRect(x: 0, y: 0, width: 150, height: 60)
        btn?.setTitle("ShowWebVC", for: .normal)
        btn?.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        btn?.setTitleColor(.black, for: .normal)
        btn?.setTitleColor(.gray, for: .highlighted)
        btn?.addTarget(self, action: #selector(showWebVC(_:)), for: .touchUpInside)
        btn?.layer.borderWidth = 1.0
        btn?.layer.borderColor = UIColor.orange.cgColor
        btn?.layer.cornerRadius = 4.0
        view.addSubview(btn!)

        btn?.center = view.center

    }

    @IBAction func showWebVC(_ sender: UIButton) {
        navigationController?.pushViewController(MyWebVC(), animated: true)
    }
}
