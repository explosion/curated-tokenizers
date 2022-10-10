use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;

use pyo3::exceptions::{PyIOError, PyValueError};
use pyo3::{pyclass, pymethods, PyResult};
use wordpieces::{WordPieces, WordPiecesBuilder};

#[pyclass]
pub struct WordPieceProcessor {
    wordpieces: WordPieces,
}

#[pymethods]
impl WordPieceProcessor {
    #[new]
    fn new(pieces: Vec<String>) -> PyResult<Self> {
        let mut builder = WordPiecesBuilder::default();

        for (idx, piece) in pieces.into_iter().enumerate() {
            builder.insert(&piece, idx as u64)
        }

        Ok(WordPieceProcessor {
            wordpieces: builder
                .build()
                .map_err(|e| PyValueError::new_err(e.to_string()))?,
        })
    }

    fn encode(&self, token: &str) -> Option<(Vec<i64>, Vec<Option<String>>)> {
        let mut ids = Vec::new();
        let mut pieces = Vec::new();

        for piece in self.wordpieces.split(token) {
            match piece {
                wordpieces::WordPiece::Found { piece, idx } => {
                    ids.push(idx as i64);
                    let piece = if pieces.is_empty() {
                        Some(piece.to_owned())
                    } else {
                        Some(format!("##{}", piece))
                    };
                    pieces.push(piece);
                }
                wordpieces::WordPiece::Missing => {
                    ids.push(-1);
                    pieces.push(None);
                }
            }
        }

        Some((ids, pieces))
    }

    #[staticmethod]
    fn from_file(path: PathBuf) -> PyResult<Self> {
        let f = File::open(path)?;
        let wordpieces = WordPieces::from_buf_read(BufReader::new(f))
            .map_err(|e| PyIOError::new_err(e.to_string()))?;
        Ok(WordPieceProcessor { wordpieces })
    }

    fn get_initial(&self, piece: &str) -> Option<i64> {
        self.wordpieces.get_initial(piece).map(|id| id as i64)
    }

    fn to_list(&self) -> Vec<String> {
        (&self.wordpieces).into()
    }
}
