//
//  AddPlaceTableViewController.swift
//  WeThereProject
//
//  Created by 김주영 on 2021/05/28.
//

import UIKit
import MobileCoreServices
import FirebaseFirestore
import FirebaseStorage
import GooglePlaces

protocol EditDelegate {
    func didEditPlace(_ controller: AddPlaceTableViewController, data: PlaceData, image: UIImage)
}


class AddPlaceTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate{
    
    @IBOutlet var placeImageView: UIImageView!
    @IBOutlet var tfPlaceName: UITextField!
    @IBOutlet var tvPlacePosition: UITextView!
    @IBOutlet var tfCategory: UITextField!
    @IBOutlet var swVisit: UISwitch!
    @IBOutlet var pkDate: UIDatePicker!
    @IBOutlet var txvComent: UITextView!
    @IBOutlet var lblVisit: UILabel!
    @IBOutlet var lblRate: UILabel!
    @IBOutlet var btnRate1: UIButton!
    @IBOutlet var btnRate2: UIButton!
    @IBOutlet var btnRate3: UIButton!
    @IBOutlet var btnRate4: UIButton!
    @IBOutlet var btnRate5: UIButton!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var lbltTryCount: UILabel!
    
    let db: Firestore = Firestore.firestore()
    let storageRef = Storage.storage().reference()
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    var selectedImage: UIImage!
    let PICKER_VIEW_COLUMN = 1
    let searchController = GMSAutocompleteViewController()
  //  let database = Firestore.firestore()
    var category = [String]()
    var rateButtons = [UIButton]()
    let rate = AddRate()
    var isImage = true
    var dataFromInfo = false
    var count = "0"
    var receiveImage : UIImage?
    var reName = ""
    var rePositon = ""
    var reDate: Date?
    var reCategory = ""
    var reVisit = false
    var reRate = ""
    var reComent = ""
    var editData: PlaceData?
    var editDelegate: EditDelegate?
    var geoPoint: GeoPoint?
    var nowPlaceData = [PlaceData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loadCategory()
        setTextView()
        setPickerView()
       
        rateButtons.append(btnRate1)
        rateButtons.append(btnRate2)
        rateButtons.append(btnRate3)
        rateButtons.append(btnRate4)
        rateButtons.append(btnRate5)
        
        swVisit.isOn = false
    
        if dataFromInfo {
            setPlaceInfo()
            txvComent.textColor = UIColor.black
            tvPlacePosition.textColor = UIColor.black
        }
        
    }
    
    func setPickerView(){
        let categoryPicker = UIPickerView()
        let pickerToolbar = UIToolbar()
        let btnPickerDone = UIBarButtonItem()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        pickerToolbar.frame = CGRect(x: 0, y: 0, width: 0, height: 35)
      //  pickerToolbar.barTintColor = UIColor.lightGray
        self.tfCategory.inputAccessoryView = pickerToolbar
        
        btnPickerDone.title = "Done"
        btnPickerDone.target = self
        btnPickerDone.action = #selector(pickerDone)
        
        pickerToolbar.setItems([flexSpace, btnPickerDone], animated: true)
        
        categoryPicker.delegate = self
        self.tfCategory.inputView = categoryPicker
    }
    
    func setTextView(){
        txvComent.delegate = self
        tvPlacePosition.delegate = self
        txvComent.text = "코멘트를 입력하세요."
        tvPlacePosition.text = "위치를 입력하세요."
        tvPlacePosition.textColor = UIColor.lightGray
        txvComent.textColor = UIColor.lightGray
    }
    
    func loadCategory(){
        let docRef = db.collection("category").document("category")
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.category = (document.get("items") as? [String])!
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func setPlaceDataFromInfo(data: PlaceData, image: UIImage){
        receiveImage = image
        selectedImage = image
        reName = data.name
        rePositon = data.location
        reDate = data.date
        reCategory = data.category
        reVisit = data.visit
        reRate = data.rate
        reComent = data.coment
        geoPoint = data.geopoint
        count = data.count
        dataFromInfo = true
        
        editData = data
    }
    
    func setPlaceInfo(){
        placeImageView.image = receiveImage
        
        tfPlaceName.text = reName as String
        tvPlacePosition.text = rePositon
        tfCategory.text = reCategory
        swVisit.isOn = reVisit
        pkDate.date = reDate!
        txvComent.text = reComent
        lblRate.text = reRate
        lbltTryCount.text = Int(count)!.description + "회"
        stepper.value = NSString(string: count).doubleValue
        
        if reVisit == true{
            for btn in rateButtons{
                btn.isEnabled = true
            }
            lblVisit.text = "가봤어요!"
        }else{
            for btn in rateButtons{
                btn.isEnabled = false
                btn.setImage(UIImage(systemName: "star"), for: .normal)
            }
            lblRate.text = "0.0"
            lblVisit.text = "가보고 싶어요!"
        }
        rate.fill(buttons: rateButtons, rate: NSString(string: reRate).floatValue)
    }
    
    @objc func pickerDone(){
        self.view.endEditing(true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 9
    }

    @IBAction func btnAddDone(_ sender: UIButton){
        let i = nowPlaceData.first(where: {$0.name == tfPlaceName.text})
        if i != nil{
            myAlert("장소 이름 중복", message: "같은 이름의 장소가 존재합니다.")
        }else if tfPlaceName.text == ""{
            myAlert("필수 입력 미기재", message: "장소의 이름을 입력해주세요.")
        }else if tvPlacePosition.text == "위치를 입력하세요."{
            myAlert("필수 입력 미기재", message: "장소의 위치를 입력해주세요.")
        }else if tfCategory.text == "" {
            myAlert("필수 입력 미기재", message: "장소의 카테고리를 선택해주세요.")
        }else if geoPoint == nil {
            myAlert("장소 위치 선택 오류", message: "장소의 이름 또는 주소를 검색하여 선택해주세요.")
        }else{
            //    tfPlaceName.placeholder = "이름을 입력하세요."
            
            if receiveImage == nil {
                if selectedImage == nil{
                    isImage = false
                }else{
                    uploadImage(tfPlaceName.text!, image: selectedImage)
                    placeImages.updateValue(selectedImage, forKey: tfPlaceName.text!)
                    isImage = true
                }
            }else if receiveImage != selectedImage{
                uploadImage(tfPlaceName.text!, image: selectedImage)
                placeImages.updateValue(selectedImage, forKey: tfPlaceName.text!)
                isImage = true
            }
                       
            
            if txvComent.text == "코멘트를 입력하세요."{
                txvComent.text = ""
            }
            
            uploadData()
            
            if editDelegate != nil{
                editData?.name = tfPlaceName.text!
                editData?.location = tvPlacePosition.text
                editData?.category = tfCategory.text!
                editData?.visit = swVisit.isOn
                editData?.date = pkDate.date
                editData?.coment = txvComent.text
                editData?.rate = lblRate.text!
                editData?.geopoint = geoPoint!
                editData?.count = count
            
                editDelegate?.didEditPlace(self, data: editData!, image: selectedImage)
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlaceUpdate"), object: nil)
           
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func uploadData(){
        if reName != "" && reName != tfPlaceName.text! {
            db.collection("users").document(reName).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
        }
        let docData: [String: Any] = [
            "name": tfPlaceName.text!,
            "position": tvPlacePosition.text!,
            "date": pkDate.date,  //Timestamp(date: Date()),
            "visit": swVisit.isOn,
            "count": count,
            "rate": lblRate.text!,
            "coment": txvComent.text!,
            "category": tfCategory.text!,
            "geopoint": geoPoint!,
            "image": isImage
        ]

        db.collection("users").document(tfPlaceName.text!).setData(docData) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray{
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    /*
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "코멘트를 입력하세요."
            textView.textColor = UIColor.lightGray
        }
    }
*/
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return PICKER_VIEW_COLUMN
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return category.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return category[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tfCategory.text = category[row]
    }
    
    @IBAction func switchOn(_ sender: UISwitch){
        if sender.isOn == true{
            for btn in rateButtons{
                btn.isEnabled = true
            }
            lblVisit.text = "가봤어요!"
        }else{
            for btn in rateButtons{
                btn.isEnabled = false
                btn.setImage(UIImage(systemName: "star"), for: .normal)
            }
            lblRate.text = "0.0"
            lblVisit.text = "가보고 싶어요!"
            
        }
    }
    
    @IBAction func clickStar(_ sender: UIButton){
        lblRate.text = String(describing: rate.checkAttr(buttons: rateButtons, button: sender))
    }
    
    @IBAction func btnAddPhoto(_ sender: UIButton){
        if(UIImagePickerController.isSourceTypeAvailable(.photoLibrary)){
            
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = true
                
            present(imagePicker, animated: true, completion: nil)
        }else{
            myAlert("Photo album inaccessable", message: "Application cannot access the photo album.")
        }
    }
    
    @IBAction func updownStepper(_ sender: UIStepper) {
        lbltTryCount.text = Int(sender.value).description + "회"
        count = Int(sender.value).description
    }
    
    @IBAction func searchPosition(_ sender: UIButton){
        //구글 자동완성 뷰컨트롤러 생성
        searchController.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage //사진을 가져와 라이브러리에 저장

        placeImageView.image = selectedImage
        self.dismiss(animated: true, completion: nil)   //현재 뷰 컨트롤러 제거
    }
        
    //사용자가 사진이나 비디오를 찍지 않고 취소했을 때
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)   //이미지 피커를 제거하고 초기 뷰를 보여줌
    }
        
    func uploadImage(_ path: String, image: UIImage){
        var data = Data()
        data = image.jpegData(compressionQuality: 0.8)!
        let filePath = path
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        storageRef.child(filePath).putData(data, metadata: metaData){
            (metaData, error) in if let error = error{
                print(error.localizedDescription)
                return
            }else{
                print("Image successfully upload!")
            }
        }
    }
    
    //경고 표시
    func myAlert(_ title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    


    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension AddPlaceTableViewController: GMSAutocompleteViewControllerDelegate { //해당 뷰컨트롤러를 익스텐션으로 딜리게이트를 달아준다.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
    //     print("Place name: \(String(describing: place.name))") //셀탭한 글씨출력
        self.tvPlacePosition.text = place.formattedAddress
        self.tvPlacePosition.textColor = UIColor.black
        self.tvPlacePosition.isEditable = true
        self.geoPoint = GeoPoint(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        dismiss(animated: true, completion: nil) //화면꺼지게
        
    } //원하는 셀 탭했을 때 꺼지게
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)//에러났을 때 출력
    } //실패했을 때
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil) //화면 꺼지게
    } //캔슬버튼 눌렀을 때 화면 꺼지게
    
}

