import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [movies, setMovies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const apiUrl =
    process.env.REACT_APP_MOVIE_API_URL || 'http://localhost:5000';

  useEffect(() => {
    let isMounted = true;
    fetch(`${apiUrl}/movies`)
      .then((res) => {
        if (!res.ok) {
          throw new Error(`HTTP error! status: ${res.status}`);
        }
        return res.json();
      })
      .then((data) => {
        if (isMounted) {
          setMovies(data.movies || []);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (isMounted) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [apiUrl]);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Movie Picture Pipeline</h1>
      </header>
      <main className="App-main">
        <section className="movie-container">
          <h2>Movie List</h2>
          {loading && <p className="status-message">Loading movies...</p>}
          {error && (
            <p className="status-message error">
              Failed to load movies: {error}
            </p>
          )}
          {!loading && !error && (
            <ul className="movie-list" data-testid="movie-list">
              {movies.map((movie) => (
                <li key={movie.id} className="movie-item">
                  <span className="movie-title">{movie.title}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}

export default App;
