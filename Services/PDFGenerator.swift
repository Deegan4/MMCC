import Foundation
import UIKit

enum PDFGenerator {
    // MARK: - Proposal PDF

    static func generateProposalPDF(
        proposal: Proposal,
        profile: BusinessProfile,
        isPro: Bool = false
    ) -> Data {
        var html = proposalHTML(proposal: proposal, profile: profile)
        if !isPro {
            html = appendWatermark(to: html)
        }
        return renderHTMLToPDF(html: html)
    }

    // MARK: - Invoice PDF

    static func generateInvoicePDF(
        invoice: Invoice,
        profile: BusinessProfile,
        isPro: Bool = false
    ) -> Data {
        var html = invoiceHTML(invoice: invoice, profile: profile)
        if !isPro {
            html = appendWatermark(to: html)
        }
        return renderHTMLToPDF(html: html)
    }

    // MARK: - Free Tier Watermark

    private static func appendWatermark(to html: String) -> String {
        html.replacingOccurrences(
            of: "</body></html>",
            with: """
            <div style="text-align: center; margin-top: 24px; padding-top: 12px; border-top: 1px solid #eee;">
                <p style="font-size: 9px; color: #999; letter-spacing: 1px;">Powered by MMCC &mdash; HVAC Contractor Estimates</p>
            </div>
            </body></html>
            """
        )
    }

    // MARK: - HTML Rendering

    private static func renderHTMLToPDF(html: String) -> Data {
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36

        let printableRect = CGRect(
            x: margin, y: margin,
            width: pageWidth - margin * 2,
            height: pageHeight - margin * 2
        )
        let paperRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIPrintPageRenderer()
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        formatter.perPageContentInsets = UIEdgeInsets(
            top: margin, left: margin, bottom: margin, right: margin
        )
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        for i in 0 ..< renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: - Proposal HTML

    private static func proposalHTML(proposal: Proposal, profile: BusinessProfile) -> String {
        let dateStr = proposal.createdAt.formatted(date: .abbreviated, time: .omitted)
        let validStr = proposal.validUntil?.formatted(date: .abbreviated, time: .omitted) ?? ""

        var html = """
        <html><head><style>\(cssStyles)</style></head><body>
        <div class="header">
            <div class="company">
                <h1>\(esc(profile.businessName.isEmpty ? "MMCC Proposal" : profile.businessName))</h1>
                \(profile.formattedAddress.isEmpty ? "" : "<p>\(esc(profile.formattedAddress))</p>")
                \(profile.phone.isEmpty ? "" : "<p>\(esc(profile.phone))</p>")
                \(profile.email.isEmpty ? "" : "<p>\(esc(profile.email))</p>")
                \(profile.licenseNumber.isEmpty ? "" : "<p>License: \(esc(profile.licenseNumber))</p>")
            </div>
            <div class="doc-info">
                <h2>PROPOSAL</h2>
                <p><strong>P-\(String(format: "%03d", proposal.number))</strong></p>
                <p>Date: \(dateStr)</p>
                \(validStr.isEmpty ? "" : "<p>Valid Until: \(validStr)</p>")
                <p>Status: \(proposal.status.displayName)</p>
            </div>
        </div>
        """

        // Customer
        if let customer = proposal.customer {
            html += """
            <div class="customer">
                <h3>Bill To:</h3>
                <p><strong>\(esc(customer.name))</strong></p>
                \(customer.phone.isEmpty ? "" : "<p>\(esc(customer.phone))</p>")
                \(customer.email.isEmpty ? "" : "<p>\(esc(customer.email))</p>")
                \(customer.address.isEmpty ? "" : "<p>\(esc(customer.address))</p>")
            </div>
            """
        }

        // Job details
        if !proposal.jobAddress.isEmpty || proposal.systemType != nil || proposal.serviceType != nil {
            html += "<div class='jobsite'><h3>Job Details:</h3>"
            if !proposal.jobAddress.isEmpty { html += "<p>\(esc(proposal.jobAddress))</p>" }
            if let st = proposal.systemType { html += "<p>System: \(st.displayName)</p>" }
            if let svc = proposal.serviceType { html += "<p>Service: \(svc.displayName)</p>" }
            if let pt = proposal.propertyType { html += "<p>Property: \(pt.displayName)</p>" }
            html += "</div>"
        }

        // Sections with line items
        for section in proposal.sortedSections {
            html += """
            <h3 class="section-title">\(esc(section.name))</h3>
            <table>
                <tr><th>Description</th><th>Qty</th><th>Unit</th><th>Unit Price</th><th>Total</th></tr>
            """
            for item in section.sortedLineItems {
                html += """
                <tr>
                    <td>\(esc(item.itemDescription))</td>
                    <td class="num">\(item.quantity.formatted())</td>
                    <td class="num">\(esc(item.unit))</td>
                    <td class="num">\(item.unitPrice.formatted(.currency(code: "USD")))</td>
                    <td class="num">\(item.lineTotal.formatted(.currency(code: "USD")))</td>
                </tr>
                """
            }
            html += """
                <tr class="subtotal"><td colspan="4">Section Total</td><td class="num">\(section.subtotal.formatted(.currency(code: "USD")))</td></tr>
            </table>
            """
        }

        // Totals
        html += "<div class='totals'><table class='totals-table'>"
        html += "<tr><td>Subtotal</td><td class='num'>\(proposal.subtotal.formatted(.currency(code: "USD")))</td></tr>"
        if proposal.markupAmount > 0 {
            html += "<tr><td>Markup (\(proposal.markup)%)</td><td class='num'>\(proposal.markupAmount.formatted(.currency(code: "USD")))</td></tr>"
        }
        if proposal.taxAmount > 0 {
            html += "<tr><td>Tax (\(proposal.taxRate)%)</td><td class='num'>\(proposal.taxAmount.formatted(.currency(code: "USD")))</td></tr>"
        }
        html += "<tr class='grand-total'><td><strong>Grand Total</strong></td><td class='num'><strong>\(proposal.grandTotal.formatted(.currency(code: "USD")))</strong></td></tr>"
        html += "</table></div>"

        // Notes & Terms
        if !proposal.notes.isEmpty {
            html += "<div class='notes'><h3>Notes</h3><p>\(esc(proposal.notes).replacingOccurrences(of: "\n", with: "<br>"))</p></div>"
        }
        if !proposal.terms.isEmpty {
            html += "<div class='terms'><h3>Terms & Conditions</h3><p>\(esc(proposal.terms).replacingOccurrences(of: "\n", with: "<br>"))</p></div>"
        }

        html += "</body></html>"
        return html
    }

    // MARK: - Invoice HTML

    private static func invoiceHTML(invoice: Invoice, profile: BusinessProfile) -> String {
        let dateStr = invoice.createdAt.formatted(date: .abbreviated, time: .omitted)
        let dueStr = invoice.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? ""

        var html = """
        <html><head><style>\(cssStyles)</style></head><body>
        <div class="header">
            <div class="company">
                <h1>\(esc(profile.businessName.isEmpty ? "MMCC Invoice" : profile.businessName))</h1>
                \(profile.formattedAddress.isEmpty ? "" : "<p>\(esc(profile.formattedAddress))</p>")
                \(profile.phone.isEmpty ? "" : "<p>\(esc(profile.phone))</p>")
                \(profile.email.isEmpty ? "" : "<p>\(esc(profile.email))</p>")
                \(profile.licenseNumber.isEmpty ? "" : "<p>License: \(esc(profile.licenseNumber))</p>")
            </div>
            <div class="doc-info">
                <h2>INVOICE</h2>
                <p><strong>INV-\(String(format: "%03d", invoice.number))</strong></p>
                <p>Date: \(dateStr)</p>
                \(dueStr.isEmpty ? "" : "<p>Due: \(dueStr)</p>")
                <p>Terms: \(invoice.paymentTerms.displayName)</p>
            </div>
        </div>
        """

        // Customer
        if let customer = invoice.customer {
            html += """
            <div class="customer">
                <h3>Bill To:</h3>
                <p><strong>\(esc(customer.name))</strong></p>
                \(customer.phone.isEmpty ? "" : "<p>\(esc(customer.phone))</p>")
                \(customer.email.isEmpty ? "" : "<p>\(esc(customer.email))</p>")
                \(customer.address.isEmpty ? "" : "<p>\(esc(customer.address))</p>")
            </div>
            """
        }

        // Job site
        if !invoice.jobAddress.isEmpty {
            html += "<div class='jobsite'><h3>Job Site:</h3>"
            html += "<p>\(esc(invoice.jobAddress))</p>"
            html += "</div>"
        }

        // Sections with line items
        for section in invoice.sortedSections {
            html += """
            <h3 class="section-title">\(esc(section.name))</h3>
            <table>
                <tr><th>Description</th><th>Qty</th><th>Unit</th><th>Unit Price</th><th>Total</th></tr>
            """
            for item in section.sortedLineItems {
                html += """
                <tr>
                    <td>\(esc(item.itemDescription))</td>
                    <td class="num">\(item.quantity.formatted())</td>
                    <td class="num">\(esc(item.unit))</td>
                    <td class="num">\(item.unitPrice.formatted(.currency(code: "USD")))</td>
                    <td class="num">\(item.lineTotal.formatted(.currency(code: "USD")))</td>
                </tr>
                """
            }
            html += """
                <tr class="subtotal"><td colspan="4">Section Total</td><td class="num">\(section.subtotal.formatted(.currency(code: "USD")))</td></tr>
            </table>
            """
        }

        // Totals
        html += "<div class='totals'><table class='totals-table'>"
        html += "<tr><td>Subtotal</td><td class='num'>\(invoice.subtotal.formatted(.currency(code: "USD")))</td></tr>"
        if invoice.taxAmount > 0 {
            html += "<tr><td>Tax (\(invoice.taxRate)%)</td><td class='num'>\(invoice.taxAmount.formatted(.currency(code: "USD")))</td></tr>"
        }
        html += "<tr class='grand-total'><td><strong>Grand Total</strong></td><td class='num'><strong>\(invoice.grandTotal.formatted(.currency(code: "USD")))</strong></td></tr>"
        if invoice.totalPaid > 0 {
            html += "<tr><td>Paid</td><td class='num'>(\(invoice.totalPaid.formatted(.currency(code: "USD"))))</td></tr>"
            html += "<tr class='grand-total'><td><strong>Balance Due</strong></td><td class='num'><strong>\(invoice.balanceDue.formatted(.currency(code: "USD")))</strong></td></tr>"
        }
        html += "</table></div>"

        // Payments
        if !(invoice.payments ?? []).isEmpty {
            html += "<div class='payments'><h3>Payments Received</h3><table>"
            html += "<tr><th>Date</th><th>Method</th><th>Amount</th><th>Note</th></tr>"
            for payment in (invoice.payments ?? []).sorted(by: { $0.date < $1.date }) {
                html += """
                <tr>
                    <td>\(payment.date.formatted(date: .abbreviated, time: .omitted))</td>
                    <td>\(payment.method.displayName)</td>
                    <td class="num">\(payment.amount.formatted(.currency(code: "USD")))</td>
                    <td>\(esc(payment.note))</td>
                </tr>
                """
            }
            html += "</table></div>"
        }

        // Notes & Terms
        if !invoice.notes.isEmpty {
            html += "<div class='notes'><h3>Notes</h3><p>\(esc(invoice.notes).replacingOccurrences(of: "\n", with: "<br>"))</p></div>"
        }
        if !invoice.terms.isEmpty {
            html += "<div class='terms'><h3>Terms & Conditions</h3><p>\(esc(invoice.terms).replacingOccurrences(of: "\n", with: "<br>"))</p></div>"
        }

        html += "</body></html>"
        return html
    }

    // MARK: - CSS

    private static var cssStyles: String {
        """
        body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 11px; color: #333; line-height: 1.4; }
        .header { display: flex; justify-content: space-between; margin-bottom: 20px; border-bottom: 2px solid #AF6118; padding-bottom: 12px; }
        .company h1 { font-size: 18px; margin: 0 0 4px 0; color: #AF6118; }
        .company p { margin: 1px 0; color: #666; font-size: 10px; }
        .doc-info { text-align: right; }
        .doc-info h2 { font-size: 22px; margin: 0; color: #AF6118; letter-spacing: 2px; }
        .doc-info p { margin: 2px 0; font-size: 10px; }
        .customer, .jobsite { margin: 12px 0; padding: 8px; background: #f8f8f8; border-radius: 4px; }
        .customer h3, .jobsite h3 { font-size: 10px; color: #999; text-transform: uppercase; letter-spacing: 1px; margin: 0 0 4px 0; }
        .customer p, .jobsite p { margin: 1px 0; font-size: 11px; }
        .section-title { font-size: 12px; color: #AF6118; border-bottom: 1px solid #ddd; padding-bottom: 4px; margin-top: 16px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
        th { background: #f0f0f0; padding: 5px 8px; text-align: left; font-size: 9px; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #ddd; }
        td { padding: 4px 8px; border-bottom: 1px solid #eee; font-size: 10px; }
        .num { text-align: right; }
        .subtotal { background: #f8f8f8; font-weight: 600; }
        .subtotal td { border-top: 1px solid #ddd; }
        .totals { margin-top: 16px; }
        .totals-table { width: 250px; margin-left: auto; }
        .totals-table td { padding: 3px 8px; font-size: 11px; }
        .grand-total td { border-top: 2px solid #AF6118; font-size: 13px; padding-top: 6px; }
        .notes, .terms, .payments { margin-top: 16px; padding-top: 8px; border-top: 1px solid #eee; }
        .notes h3, .terms h3, .payments h3 { font-size: 10px; color: #999; text-transform: uppercase; letter-spacing: 1px; margin: 0 0 4px 0; }
        .notes p, .terms p { font-size: 10px; color: #666; }
        """
    }

    // MARK: - Helpers

    private static func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
