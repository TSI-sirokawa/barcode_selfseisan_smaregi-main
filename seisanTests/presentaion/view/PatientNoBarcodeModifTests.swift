//
//  seisan.StanbyPatientCardViewModel.PatientNoBarcodeModifTests.swift
//  seisanTests
//
//  Created by 加治木啓之 on 2023/09/18.
//

import XCTest
@testable import seisan

final class PatientNoBarcodeModifTests: XCTestCase {
    // 下位N桁使用
    func test_getBarcodeTextLowerDigits_minus1() throws {
        let barcodeText = "7654321"
        let digits = -1
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_getBarcodeTextLowerDigits_0() throws {
        let barcodeText = "7654321"
        let digits = 0
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_getBarcodeTextLowerDigits_1() throws {
        let barcodeText = "7654321"
        let digits = 1
        let expected = "1"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_getBarcodeTextLowerDigits_6() throws {
        let barcodeText = "7654321"
        let digits = 6
        let expected = "654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_getBarcodeTextLowerDigits_7() throws {
        let barcodeText = "7654321"
        let digits = 7
        let expected = "7654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_getBarcodeTextLowerDigits_8() throws {
        let barcodeText = "7654321"
        let digits = 8
        let expected = "7654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.getBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    // 下位X桁削除
    func test_removeBarcodeTextLowerDigits_minus1() throws {
        let barcodeText = "7654321"
        let digits = -1
        let expected = "7654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_0() throws {
        let barcodeText = "7654321"
        let digits = 0
        let expected = "7654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_1() throws {
        let barcodeText = "7654321"
        let digits = 1
        let expected = "765432"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_4() throws {
        let barcodeText = "7654321"
        let digits = 4
        let expected = "765"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_6() throws {
        let barcodeText = "7654321"
        let digits = 6
        let expected = "7"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_7() throws {
        let barcodeText = "7654321"
        let digits = 7
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_8() throws {
        let barcodeText = "7654321"
        let digits = 8
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextLowerDigits(barcodeText, digits: digits), expected)
    }
    
    // 前ゼロ削除
    func test_removeBarcodeTextLowerDigits_notExist0() throws {
        let barcodeText = "7654321"
        let expected = "7654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextZeroPrefix(barcodeText), expected)
    }
    
    func test_removeBarcodeTextLowerDigits_exist0() throws {
        let barcodeText = "0654321"
        let expected = "654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif()
        XCTAssertEqual(barcodeModif.removeBarcodeTextZeroPrefix(barcodeText), expected)
    }
    
    // 組み合わせ
    func test_modifyBarcodeText_lowerDigits_0__removeLowerDigits_0__removeZeroPrefix_0() throws {
        let barcodeText = "0654321"
        
        let isPatientNoLowerDigitsEnable = false
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = false
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = "0654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_0__removeLowerDigits_0__removeZeroPrefix_1() throws {
        let barcodeText = "0654321"
        
        let isPatientNoLowerDigitsEnable = false
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = false
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = true
        
        let expected = "654321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_0__removeLowerDigits_1__removeZeroPrefix_0() throws {
        let barcodeText = "0654321"
        
        let isPatientNoLowerDigitsEnable = false
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = "065432"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_0__removeLowerDigits_1__removeZeroPrefix_1() throws {
        let barcodeText = "0654321"
        
        let isPatientNoLowerDigitsEnable = false
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = true
        
        let expected = "65432"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_1__removeLowerDigits_0__removeZeroPrefix_0() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = false
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = "04321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_1__removeLowerDigits_0__removeZeroPrefix_1() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = false
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = true
        
        let expected = "4321"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_1__removeLowerDigits_1__removeZeroPrefix_0() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = "0432"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_lowerDigits_1__removeLowerDigits_1__removeZeroPrefix_1() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 1
        let isPatientNoRemoveZeroPrefixEnable = true
        
        let expected = "432"
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    // 「下位X桁削除の桁数」が「下位N桁使用の桁数」以上
    func test_modifyBarcodeText_removeLowerDigits_greaterEqual_lowerDigits() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 5
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
    
    func test_modifyBarcodeText_removeLowerDigits_greaterThen_lowerDigits() throws {
        let barcodeText = "0004321"
        
        let isPatientNoLowerDigitsEnable = true
        let patientNoLowerDigits = 5
        let isPatientNoRemoveLowerDigitsEnable = true
        let patientNoRemoveLowerDigits = 6
        let isPatientNoRemoveZeroPrefixEnable = false
        
        let expected = ""
        
        let barcodeModif = seisan.StanbyPatientCardViewModel.PatientNoBarcodeModif(
            isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
            patientNoLowerDigits: patientNoLowerDigits,
            isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
            isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable
        )
        XCTAssertEqual(barcodeModif.modifyBarcodeText(barcodeText), expected)
    }
}
