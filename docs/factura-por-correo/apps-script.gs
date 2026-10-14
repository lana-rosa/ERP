// BORRADOR — no instalado. Google Apps Script en la cuenta de Gmail que recibe los correos de la DIAN.
// Propiedades del script: URL (función de Supabase) y CLAVE (la que cuya huella está en la función).
const ETIQUETA = 'ERP-procesado';
const BUSQUEDA = 'from:dian.gov.co has:attachment (filename:zip OR filename:xml) -label:' + ETIQUETA; // ajustar con el primer correo real

function procesarFacturasDian() {
  const p = PropertiesService.getScriptProperties();
  const url = p.getProperty('URL'), clave = p.getProperty('CLAVE');
  const etiqueta = GmailApp.getUserLabelByName(ETIQUETA) || GmailApp.createLabel(ETIQUETA);
  GmailApp.search(BUSQUEDA, 0, 20).forEach(hilo => {
    let todoBien = true;
    hilo.getMessages().forEach(msg => {
      msg.getAttachments().forEach(a => {
        if (!/\.(zip|xml)$/i.test(a.getName()) || a.getSize() > 5000000) return;
        const r = UrlFetchApp.fetch(url, {
          method: 'post', contentType: 'application/json', muteHttpExceptions: true,
          headers: { 'x-clave-correo': clave },
          payload: JSON.stringify({ message_id: msg.getId(), nombre: a.getName(), archivo_base64: Utilities.base64Encode(a.getBytes()) }),
        });
        if (r.getResponseCode() !== 200) todoBien = false;
      });
    });
    if (todoBien) hilo.addLabel(etiqueta);
  });
}
// Disparador: Editar → Activadores → procesarFacturasDian → cada 10 minutos.
