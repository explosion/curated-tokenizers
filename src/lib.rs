use pyo3::prelude::PyModule;
use pyo3::{pymodule, PyResult, Python};

mod sentencepiece_processor;
use sentencepiece_processor::SentencePieceProcessor;

mod wordpiece_processor;
use wordpiece_processor::WordPieceProcessor;

#[pymodule]
fn cutlery(_py: Python<'_>, m: &PyModule) -> PyResult<()> {
    m.add_class::<SentencePieceProcessor>()?;
    m.add_class::<WordPieceProcessor>()?;
    Ok(())
}
