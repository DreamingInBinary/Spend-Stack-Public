//
//  SSListExporter.m
//  Spend Stack
//
//  Created by Jordan Morgan on 8/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListExporter.h"

typedef NS_ENUM(NSUInteger, ListExportScenario) {
    ListExportScenarioSingleList,
    ListExportScenarioMultipleLists,
    ListExportScenarioSnapshot
};

static inline NSString *numString (NSDecimalNumber *val, TaxUtility *taxUtil) {
    return [taxUtil guranteedCurrencyString:val.stringValue];
}

static inline CGRect USPaperSize () {
    return CGRectMake(0, 0, 612, 792);
}

@interface SSListExporter()

@property (nonatomic) ListExportScenario scenario;
@property (strong, nonatomic, nullable) NSArray <SSListExporter *> *multiListExporter;
@property (strong, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nullable) NSDiffableDataSourceSnapshot<SSListTag *, SSListItem *> *snapshot;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSListExporter

#pragma mark - Initializer

- (instancetype)initWithSnapshot:(NSDiffableDataSourceSnapshot<SSListTag *,SSListItem *> *)snapshot list:(SSList * _Nonnull)list
{
    self = [super init];
    
    if (self)
    {
        self.scenario = ListExportScenarioSnapshot;
        self.snapshot = snapshot;
        self.list = [list deepCopy];
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:self.list.currencyIdentifier];
    }
    
    return self;
}

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        self.scenario = ListExportScenarioSingleList;
        self.list = [list deepCopy];
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:self.list.currencyIdentifier];
    }
    
    return self;
}

- (instancetype)initWithLists:(NSArray<SSList *> *)lists
{
    self = [super init];
    
    if (self)
    {
        self.scenario = ListExportScenarioMultipleLists;
        
        NSMutableArray <SSListExporter *> *mutableExporters = [NSMutableArray new];
        for (SSList *list in lists)
        {
            SSListExporter *listExporter = [[SSListExporter alloc] initWithList:[list deepCopy]];
            [mutableExporters addObject:listExporter];
        }
        
        self.multiListExporter = [NSArray arrayWithArray:mutableExporters];
    }
    
    return self;
}

#pragma mark - Generators

- (NSAttributedString *)textRepresentationForList
{
    NSDictionary *headerAttributes = @{NSForegroundColorAttributeName:[UIColor ssMainFontColor],
                                       NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]};
    NSDictionary *sectionAttributes = @{NSForegroundColorAttributeName:[UIColor ssMainFontColor],
                                        NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]};
    NSDictionary *bodyAttributes = @{NSForegroundColorAttributeName:[UIColor ssMainFontColor],
                                     NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    
    NSMutableAttributedString *attributedText;
    NSString *headerText = [NSString stringWithFormat:@"%@\n\n", self.list.name];
    NSMutableString *bodyText = [NSMutableString new];
    NSMutableString *breakDownText = [NSMutableString new];
    NSString *finalString;
    
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateStyle = NSDateFormatterShortStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    
    // Create body
    if (self.scenario == ListExportScenarioSnapshot)
    {
        for (SSListTag *tag in self.snapshot.sectionIdentifiers)
        {
            // Append section title
            [bodyText appendString:[NSString stringWithFormat:@"\n%@",tag.name]];
            
            // Append items
            for (SSListItem *item in self.snapshot.itemIdentifiers)
            {
                SSListTag *itemTag = item.tag ?: [SSListTag miscTag];
                if ([itemTag isEqual:tag])
                {
                    [bodyText appendString:[NSString stringWithFormat:@"\n  %@ - %@ (%@)", item.title, numString([item calcTotalAmount:self.list.taxInfo taxUtil:self.taxUtil], self.taxUtil), [df stringFromDate:item.customDate] ?: @""]];
                }
            }
        }
    }
    else
    {
        for (SSListTag *tag in self.list.datasourceAdapter.sortedTags)
        {
            // Append section title
            [bodyText appendString:[NSString stringWithFormat:@"\n%@",tag.name]];
            
            // Append items
            for (SSListItem *item in self.list.datasourceAdapter.itemsByTag[tag])
            {
                [bodyText appendString:[NSString stringWithFormat:@"\n  %@ - %@ (%@)", item.title, numString([item calcTotalAmount:self.list.taxInfo taxUtil:self.taxUtil], self.taxUtil), [df stringFromDate:item.customDate] ?: @""]];
            }
        }
    }
    
    // Total
    [breakDownText appendString:[NSString stringWithFormat:ss_Localized(@"export.subTotal"), numString([self.list calcBaseCost], self.taxUtil)]];
    
    [breakDownText appendString:[NSString stringWithFormat:ss_Localized(@"export.tax"), numString([self.list calcTaxAmount], self.taxUtil)]];
    
    [breakDownText appendString:[NSString stringWithFormat:ss_Localized(@"export.discount"), numString([self.list calcDiscountAmount], self.taxUtil)]];
    [breakDownText appendString:[NSString stringWithFormat:ss_Localized(@"export.total"), numString([self.list calcTotalCost], self.taxUtil)]];
    
    // Apply attributes
    finalString = [[headerText stringByAppendingString:bodyText] stringByAppendingString:breakDownText];
    attributedText = [[NSMutableAttributedString alloc] initWithString:finalString];
    [attributedText setAttributes:headerAttributes range:NSMakeRange(0, headerText.length)];
    [attributedText setAttributes:bodyAttributes range:NSMakeRange(headerText.length, bodyText.length)];
    [attributedText setAttributes:sectionAttributes range:NSMakeRange((headerText.length + bodyText.length), breakDownText.length)];
    
    return [attributedText copy];
}

- (NSAttributedString *)textRepresentationForLists
{
    if (self.scenario != ListExportScenarioMultipleLists)
    {
        return nil;
    }
    
    NSMutableAttributedString *concatString = [NSMutableAttributedString new];
    
    for (SSListExporter *listExport in self.multiListExporter)
    {
        [concatString appendAttributedString:[listExport textRepresentationForList]];
    }
    
    return [concatString copy];
}

- (UIImage *)imageRepresentationForList:(UITableView *)tableView
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:tableView.contentSize];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGPoint savedContentOffset = tableView.contentOffset;
        CGRect savedFrame = tableView.frame;
        
        tableView.contentOffset = CGPointZero;
        tableView.frame = CGRectMake(0, 0, tableView.contentSize.width, tableView.contentSize.height);
        
        [tableView.layer renderInContext:ctx.CGContext];
        
        tableView.contentOffset = savedContentOffset;
        tableView.frame = savedFrame;
    }];
}

- (NSData *)pdfRepresentationForList
{
    UIGraphicsPDFRendererFormat *format = [UIGraphicsPDFRendererFormat new];
    format.documentInfo = @{(NSString *)kCGPDFContextAuthor :@"Spend Stack",
                            (NSString *)kCGPDFContextTitle:self.list.name
                            };
    
    UIGraphicsPDFRenderer *renderer = [[UIGraphicsPDFRenderer alloc] initWithBounds:USPaperSize()
                                                                             format:format];
    return [renderer PDFDataWithActions:^(UIGraphicsPDFRendererContext *ctx) {
        [ctx beginPage];
        // Figure out page breaks, can pretty it up in a later release
        [[self textRepresentationForList] drawInRect:CGRectInset(ctx.format.bounds, 50, 50)];
    }];
}

- (NSData *)pdfRepresentationForLists
{
    UIGraphicsPDFRendererFormat *format = [UIGraphicsPDFRendererFormat new];
    format.documentInfo = @{(NSString *)kCGPDFContextAuthor :@"Spend Stack",
                            (NSString *)kCGPDFContextTitle:@"Spend Stack Lists"
                            };
    
    UIGraphicsPDFRenderer *renderer = [[UIGraphicsPDFRenderer alloc] initWithBounds:USPaperSize()
                                                                             format:format];
    return [renderer PDFDataWithActions:^(UIGraphicsPDFRendererContext *ctx) {
        for (SSListExporter *listExport in self.multiListExporter)
        {
            [ctx beginPage];
            // Figure out page breaks, can pretty it up in a later release
            [[listExport textRepresentationForList] drawInRect:CGRectInset(ctx.format.bounds, 50, 50)];
        }
    }];
}

- (NSString *)htmlStringForList
{
    NSMutableString *htmlStr = [NSMutableString stringWithFormat:@"<h1>%@</h1>", self.list.name];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateStyle = NSDateFormatterShortStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    
    // Create body
    if (self.scenario == ListExportScenarioSnapshot)
    {
        for (SSListTag *tag in self.snapshot.sectionIdentifiers)
        {
            // Append section title
            [htmlStr appendString:[NSString stringWithFormat:@"<h3>%@</h3><ul>",tag.name]];
            
            // Append items
            for (SSListItem *item in self.snapshot.itemIdentifiers)
            {
                SSListTag *itemTag = item.tag ?: [SSListTag miscTag];
                if ([itemTag isEqual:tag])
                {
                    [htmlStr appendString:[NSString stringWithFormat:@"<li>%@ - %@ (%@)</li>", item.title, numString([item calcTotalAmount:self.list.taxInfo taxUtil:self.taxUtil], self.taxUtil), [df stringFromDate:item.customDate] ?: @""]];
                }
            }
            
            [htmlStr appendString:@"</ul>"];
        }
    }
    else
    {
        for (SSListTag *tag in self.list.datasourceAdapter.sortedTags)
        {
            // Append section title
            [htmlStr appendString:[NSString stringWithFormat:@"<h3>%@</h3><ul>",tag.name]];
            
            // Append items
            for (SSListItem *item in self.list.datasourceAdapter.itemsByTag[tag])
            {
                [htmlStr appendString:[NSString stringWithFormat:@"<li>%@ - %@ (%@)</li>", item.title, numString([item calcTotalAmount:self.list.taxInfo taxUtil:self.taxUtil], self.taxUtil), [df stringFromDate:item.customDate] ?: @""]];
            }
            
            [htmlStr appendString:@"</ul>"];
        }
    }
    
    // Breakdown
    if ([self.list calcTotalCost].doubleValue > 0)
    {
        [htmlStr appendString:ss_Localized(@"export.html.cost")];
        [htmlStr appendString:[NSString stringWithFormat:ss_Localized(@"export.html.subTotal"), numString([self.list calcBaseCost], self.taxUtil)]];
        
        [htmlStr appendString:[NSString stringWithFormat:ss_Localized(@"export.html.tax"), numString([self.list calcTaxAmount], self.taxUtil)]];
        
        [htmlStr appendString:[NSString stringWithFormat:ss_Localized(@"export.html.discount"), numString([self.list calcDiscountAmount], self.taxUtil)]];
        [htmlStr appendString:[NSString stringWithFormat:ss_Localized(@"export.html.total"), numString([self.list calcTotalCost], self.taxUtil)]];
        [htmlStr appendString:@"</p>"];
    }
    
    return [htmlStr copy];
}

- (NSString *)htmlStringForLists
{
    NSMutableString *concatString = [NSMutableString new];
    
    for (SSListExporter *listExport in self.multiListExporter)
    {
        [concatString appendString:[listExport htmlStringForList]];
    }
    
    return [concatString copy];
}

- (UIPrintInteractionController *)printControllerForList
{

    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    
    // Setup the print job
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.jobName = self.list.name;
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    
    // HTML Markup of page
    UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:[self htmlStringForList]];
    formatter.perPageContentInsets = UIEdgeInsetsMake(72, 72, 72, 72); // 1" margins
    
    // Assign print info
    printController.printInfo = printInfo;
    printController.printFormatter = formatter;
    printController.showsPaperSelectionForLoadedPapers = YES;
    
    return printController;
}

- (UIPrintInteractionController *)printControllerForLists
{
    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    
    // Setup the print job
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.jobName = @"Spend Stack Lists";
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    
    // HTML Markup of page
    UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:[self htmlStringForLists]];
    formatter.perPageContentInsets = UIEdgeInsetsMake(72, 72, 72, 72); // 1" margins
    
    // Assign print info
    printController.printInfo = printInfo;
    printController.printFormatter = formatter;
    printController.showsPaperSelectionForLoadedPapers = YES;
    
    return printController;
}

@end
