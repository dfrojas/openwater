use thiserror::Error;

#[derive(Debug, Error)]
pub enum UDDFError {
    #[error("Error al leer el archivo: {0}")]
    FileError(#[from] std::io::Error),
    #[error("Error al parsear XML: {0}")]
    ParseError(#[from] quick_xml::DeError),
}
