use std::path::PathBuf;

use pyo3::{
    exceptions::{PyOSError, PyValueError},
    pyclass, pymethods,
    types::PyBytes,
    PyResult, Python,
};
use sentencepiece::SentencePieceProcessor as RustSentencePieceProcessor;

macro_rules! unwrap_spp {
    ($boxed:expr) => {
        match $boxed.as_ref() {
            Some(v) => v,
            None => return Err(PyValueError::new_err("No sentencepiece model was loaded")),
        }
    };
}

#[pyclass]
pub struct SentencePieceProcessor {
    spp: Option<RustSentencePieceProcessor>,
}

#[pymethods]
impl SentencePieceProcessor {
    #[new]
    pub fn new() -> Self {
        SentencePieceProcessor { spp: None }
    }

    #[staticmethod]
    pub fn from_file(path: PathBuf) -> PyResult<Self> {
        let spp = RustSentencePieceProcessor::open(path)
            .map_err(|err| PyOSError::new_err(err.to_string()))?;
        Ok(SentencePieceProcessor { spp: Some(spp) })
    }

    #[staticmethod]
    pub fn from_protobuf(data: &[u8]) -> PyResult<Self> {
        let spp = RustSentencePieceProcessor::from_serialized_proto(data)
            .map_err(|err| PyValueError::new_err(err.to_string()))?;

        Ok(SentencePieceProcessor { spp: Some(spp) })
    }

    pub fn bos_id(&self) -> PyResult<Option<u32>> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp.bos_id())
    }

    pub fn decode_from_ids(&self, pieces: Vec<u32>) -> PyResult<String> {
        let spp = unwrap_spp!(self.spp);
        spp.decode_piece_ids(&pieces)
            .map_err(|err| PyValueError::new_err(err.to_string()))
    }

    pub fn decode_from_pieces(&self, pieces: Vec<&str>) -> PyResult<String> {
        let spp = unwrap_spp!(self.spp);
        spp.decode_pieces(&pieces)
            .map_err(|err| PyValueError::new_err(err.to_string()))
    }

    pub fn encode(&self, sentence: &str) -> PyResult<(Vec<u32>, Vec<String>)> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp
            .encode(sentence)
            .map_err(|err| PyValueError::new_err(err.to_string()))?
            .into_iter()
            .map(|p| (p.id, p.piece))
            .unzip())
    }

    pub fn encode_as_ids(&self, sentence: &str) -> PyResult<Vec<u32>> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp
            .encode(sentence)
            .map_err(|err| PyValueError::new_err(err.to_string()))?
            .into_iter()
            .map(|p| p.id)
            .collect())
    }

    pub fn encode_as_pieces(&self, sentence: &str) -> PyResult<Vec<String>> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp
            .encode(sentence)
            .map_err(|err| PyValueError::new_err(err.to_string()))?
            .into_iter()
            .map(|p| p.piece)
            .collect())
    }

    pub fn eos_id(&self) -> PyResult<Option<u32>> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp.eos_id())
    }

    pub fn pad_id(&self) -> PyResult<Option<u32>> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp.pad_id())
    }

    pub fn to_protobuf<'py>(&self, py: Python<'py>) -> PyResult<&'py PyBytes> {
        let spp = unwrap_spp!(self.spp);
        Ok(PyBytes::new(py, &spp.to_serialized_proto()))
    }

    pub fn unk_id(&self) -> PyResult<u32> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp.unk_id())
    }

    pub fn __len__(&self) -> PyResult<usize> {
        let spp = unwrap_spp!(self.spp);
        Ok(spp.len())
    }
}

impl Default for SentencePieceProcessor {
    fn default() -> Self {
        Self::new()
    }
}
