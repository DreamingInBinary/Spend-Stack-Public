//
//  SSTaxRateInfo+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTaxRateInfo.h"
@class TaxUtility;

static NSString * _Nonnull const sql_ListTaxRateInfoCreateTable = @""
"CREATE TABLE IF NOT EXISTS ListTaxRateInfo ( "
"taxRateInfoID TEXT PRIMARY KEY, "
"listID TEXT NOT NULL, "
"taxRate TEXT NOT NULL DEFAULT '0.00', "
"taxEnabled INTEGER NOT NULL DEFAULT 0, "
"localSalesTaxLocation TEXT, "
"didManuallySet INTEGER NULLABLE, "
"taxInfoReference BLOB, "
"taxInfoRecord BLOB NOT NULL, "
"FOREIGN KEY (listID) REFERENCES Lists(listID) ON DELETE CASCADE "
");";

static NSString * _Nonnull const sql_TaxRateInfoInsert = @""
"INSERT INTO "
"ListTaxRateInfo (taxRateInfoID, listID, taxRate, taxEnabled, localSalesTaxLocation, didManuallySet, taxInfoReference, taxInfoRecord) "
"VALUES "
"(?, ?, ?, ?, ?, ?, ?, ?);";

static NSString * _Nonnull const sql_TaxRateInfoUpdate = @""
"UPDATE ListTaxRateInfo "
"SET taxRate = (?), taxEnabled = (?), localSalesTaxLocation = (?), didManuallySet = (?), taxInfoRecord = (?) "
"WHERE taxRateInfoID = (?);";

static NSString * _Nonnull const sql_TaxRateUpdateRecord = @""
"UPDATE ListTaxRateInfo "
"SET taxInfoRecord = (?) "
"WHERE taxRateInfoID = (?);";

static NSString * _Nonnull const sql_TaxRateInfoDelete = @""
"DELETE FROM ListTaxRateInfo "
"WHERE taxRateInfoID = (?);";

static NSString * _Nonnull const sql_TaxRateIDsDelete = @""
"DELETE FROM ListTaxRateInfo "
"WHERE taxRateInfoID IN ";

static NSString * _Nonnull const sql_TaxRateSelectByTaxRateInfoID = @""
"SELECT * FROM ListTaxRateInfo "
"WHERE taxRateInfoID = (?);";

static NSString * _Nonnull const sql_TaxRateSelectByTaxRateInfoListID = @""
"SELECT * FROM ListTaxRateInfo "
"WHERE listID = (?);";

@interface SSTaxRateInfo (Utils)

- (NSDecimalNumber *_Nonnull)taxRateForCalculations:(TaxUtility * _Nonnull)taxUtil;
- (NSString * _Nonnull)taxRateStringValue;

@end
