// To parse this JSON data, do
//
//     final documentDz = documentDzFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

DocumentDz documentDzFromJson(String str) =>
    DocumentDz.fromJson(json.decode(str));

String documentDzToJson(DocumentDz data) => json.encode(data.toJson());

class DocumentDz {
  DocumentDz({
    @required this.branchId,
    @required this.memberId,
    @required this.docType,
    @required this.ownerId,
  });

  String branchId;
  String memberId;
  String docType;
  String ownerId;

  factory DocumentDz.fromJson(Map<String, dynamic> json) => DocumentDz(
        branchId: json["BranchID"] == null ? null : json["BranchID"],
        memberId: json["MemberID"] == null ? null : json["MemberID"],
        docType: json["DocType"] == null ? null : json["DocType"],
        ownerId: json["OwnerID"] == null ? null : json["OwnerID"],
      );

  Map<String, dynamic> toJson() => {
        "BranchID": branchId == null ? null : branchId,
        "MemberID": memberId == null ? null : memberId,
        "DocType": docType == null ? null : docType,
        "OwnerID": ownerId == null ? null : ownerId,
      };
}
