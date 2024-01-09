//
//  ORCARepositoryTests.swift
//  seisanTests
//
//  Created by 加治木啓之 on 2023/03/31.
//

import XCTest
@testable import seisan

import XMLCoder

class BillingConfirmTests: XCTestCase {
    
    func test_ParseBillingConfirmReponse() throws {
//        let xml = #"""
//<?xml version="1.0" encoding="UTF-8"?>
//<xmlio2>
//    <incomev3res type="record">
//        <Information_Date type="string">2023-03-31</Information_Date>
//        <Information_Time type="string">22:49:27</Information_Time>
//        <Api_Result type="string">00000</Api_Result>
//        <Api_Result_Message type="string">正常終了</Api_Result_Message>
//        <Request_Number type="string">01</Request_Number>
//        <Request_Mode type="string">02</Request_Mode>
//        <Response_Number type="string">02</Response_Number>
//        <Karte_Uid type="string">2638caa3-9b02-447a-93e7-55e61783a5cb</Karte_Uid>
//        <Orca_Uid type="string">68e2c63f-812b-4de8-833e-36ca6e73875f</Orca_Uid>
//        <Patient_ID type="string">00004</Patient_ID>
//        <Income_Detail type="record">
//            <Perform_Date type="string">2023-03-20</Perform_Date>
//            <IssuedDate type="string">2023-03-20</IssuedDate>
//            <InOut type="string">O</InOut>
//            <Invoice_Number type="string">0001149</Invoice_Number>
//            <Insurance_Combination_Number type="string">0001</Insurance_Combination_Number>
//            <Rate_Cd type="string"> 30</Rate_Cd>
//            <Department_Code type="string">01</Department_Code>
//            <Cd_Information type="record">
//                <Ac_Money type="string">       650</Ac_Money>
//                <Ic_Money type="string">       650</Ic_Money>
//                <Ai_Money type="string">       650</Ai_Money>
//                <Oe_Money type="string">         0</Oe_Money>
//            </Cd_Information>
//            <Ac_Point_Information type="record">
//                <Ac_Ttl_Point type="string">       216</Ac_Ttl_Point>
//                <Ac_Point_Detail type="array">
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">A00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">初・再診料</Ac_Point_Name>
//                        <Ac_Point type="string">       125</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">B00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">医学管理等</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">C00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">在宅療養</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">F00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">投薬</Ac_Point_Name>
//                        <Ac_Point type="string">        91</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">G00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">注射</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">J00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">処置</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">K00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">手術</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">L00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">麻酔</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">D00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">検査</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">E00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">画像診断</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">H00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">リハビリ</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">I00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">精神科専門</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">M00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">放射線治療</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">N00</Ac_Point_Code>
//                        <Ac_Point_Name type="string">病理診断</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                    <Ac_Point_Detail_child type="record">
//                        <Ac_Point_Code type="string">A10</Ac_Point_Code>
//                        <Ac_Point_Name type="string">入院料</Ac_Point_Name>
//                        <Ac_Point type="string">         0</Ac_Point>
//                    </Ac_Point_Detail_child>
//                </Ac_Point_Detail>
//            </Ac_Point_Information>
//            <Oe_Etc_Information type="record">
//                <Oe_Etc_Detail type="array">
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 1</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">文書料Ａ</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 2</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">健康診断</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 3</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">予防接種</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 4</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">自費検査</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 5</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">その他</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record"></Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record"></Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record"></Oe_Etc_Detail_child>
//                    <Oe_Etc_Detail_child type="record">
//                        <Oe_Etc_Number type="string"> 9</Oe_Etc_Number>
//                        <Oe_Etc_Name type="string">数量</Oe_Etc_Name>
//                    </Oe_Etc_Detail_child>
//                </Oe_Etc_Detail>
//            </Oe_Etc_Information>
//        </Income_Detail>
//        <Income_History type="array">
//            <Income_History_child type="record">
//                <History_Number type="string"> 1</History_Number>
//                <Processing_Date type="string">2023-03-20</Processing_Date>
//                <Processing_Time type="string">22:54</Processing_Time>
//                <Ac_Money type="string">       650</Ac_Money>
//                <Ic_Money type="string">         0</Ic_Money>
//                <State type="string">1</State>
//                <State_Name type="string">請求</State_Name>
//                <Ic_Code type="string">01</Ic_Code>
//                <Ic_Code_Name type="string">現金</Ic_Code_Name>
//            </Income_History_child>
//            <Income_History_child type="record">
//                <History_Number type="string"> 2</History_Number>
//                <Processing_Date type="string">2023-03-31</Processing_Date>
//                <Processing_Time type="string">22:27</Processing_Time>
//                <Ic_Money type="string">       650</Ic_Money>
//                <State type="string">2</State>
//                <State_Name type="string">入金</State_Name>
//                <Ic_Code type="string">03</Ic_Code>
//                <Ic_Code_Name type="string">その他</Ic_Code_Name>
//            </Income_History_child>
//        </Income_History>
//    </incomev3res>
//</xmlio2>
//"""#
//
//        let res = try! XMLDecoder().decode(seisan.ORCARepository.BillingConfirmReponse.self, from: Data(xml.utf8))
//        print("\(res)")
    }
    
    func test_ParsePaymentReponse() throws {
//        let xml = #"""
//<?xml version="1.0" encoding="UTF-8"?>
//<xmlio2>
//    <incomev3res type="record">
//        <Information_Date type="string">2023-03-31</Information_Date>
//        <Information_Time type="string">22:28:42</Information_Time>
//        <Api_Result type="string">00000</Api_Result>
//        <Api_Result_Message type="string">正常終了</Api_Result_Message>
//        <Request_Number type="string">02</Request_Number>
//        <Request_Mode type="string">01</Request_Mode>
//        <Response_Number type="string">02</Response_Number>
//        <Karte_Uid type="string">2638caa3-9b02-447a-93e7-55e61783a5cb</Karte_Uid>
//        <Orca_Uid type="string">04ca65f6-a3b8-439e-bd99-2fec306884a3</Orca_Uid>
//        <Patient_ID type="string">00004</Patient_ID>
//        <InOut type="string">O</InOut>
//        <Invoice_Number type="string">0001149</Invoice_Number>
//        <Ac_Money type="string">       650</Ac_Money>
//        <Ic_Money type="string">       650</Ic_Money>
//        <Unpaid_Money type="string">         0</Unpaid_Money>
//        <State type="string">1</State>
//        <State_Name type="string">入金済</State_Name>
//        <Income_History type="array">
//            <Income_History_child type="record">
//                <History_Number type="string"> 1</History_Number>
//                <Processing_Date type="string">2023-03-20</Processing_Date>
//                <Processing_Time type="string">22:54</Processing_Time>
//                <Ac_Money type="string">       650</Ac_Money>
//                <Ic_Money type="string">         0</Ic_Money>
//                <State type="string">1</State>
//                <State_Name type="string">請求</State_Name>
//                <Ic_Code type="string">01</Ic_Code>
//                <Ic_Code_Name type="string">現金</Ic_Code_Name>
//            </Income_History_child>
//            <Income_History_child type="record">
//                <History_Number type="string"> 2</History_Number>
//                <Processing_Date type="string">2023-03-31</Processing_Date>
//                <Processing_Time type="string">22:27</Processing_Time>
//                <Ic_Money type="string">       650</Ic_Money>
//                <State type="string">2</State>
//                <State_Name type="string">入金</State_Name>
//                <Ic_Code type="string">03</Ic_Code>
//                <Ic_Code_Name type="string">その他</Ic_Code_Name>
//            </Income_History_child>
//        </Income_History>
//    </incomev3res>
//</xmlio2>
//"""#
//
//        let res = try! XMLDecoder().decode(seisan.ORCARepository.PaymentReponse.self, from: Data(xml.utf8))
//        print("\(res)")
    }
    
    func test_ParseFiniishReponse() throws {
//        let xml = #"""
//        <?xml version="1.0" encoding="UTF-8"?>
//        <xmlio2>
//            <incomev3res type="record">
//                <Information_Date type="string">2023-04-01</Information_Date>
//                <Information_Time type="string">22:21:50</Information_Time>
//                <Api_Result type="string">00000</Api_Result>
//                <Api_Result_Message type="string">正常終了</Api_Result_Message>
//                <Request_Number type="string">99</Request_Number>
//                <Response_Number type="string">01</Response_Number>
//                <Karte_Uid type="string">2638caa3-9b02-447a-93e7-55e61783a5cb</Karte_Uid>
//                <Orca_Uid type="string">1e0318b8-c800-40f2-b0a6-8f6f63df6f76</Orca_Uid>
//            </incomev3res>
//        </xmlio2>
//"""#
//
//        let res = try! XMLDecoder().decode(seisan.ORCARepository.FiniishReponse.self, from: Data(xml.utf8))
//        print("\(res)")
    }
}
