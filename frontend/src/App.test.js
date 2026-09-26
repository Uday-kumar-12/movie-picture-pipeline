import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import App from './App';

const mockMoviesData = {
  movies: [
    { id: '123', title: 'Top Gun: Maverick' },
    { id: '456', title: 'Sonic the Hedgehog' },
    { id: '789', title: 'A Quiet Place' },
  ],
};

describe('Movie Picture Application Tests', () => {
  beforeEach(() => {
    jest.spyOn(global, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockMoviesData),
      })
    );
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('application renders without crashing', async () => {
    render(<App />);
    expect(screen.getByText(/Movie Picture Pipeline/i)).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByText('Top Gun: Maverick')).toBeInTheDocument();
    });
  });

  test('Movie List heading exists', async () => {
    render(<App />);
    const headingElement = screen.getByRole('heading', {
      name: /Movie List/i,
      level: 2,
    });
    expect(headingElement).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByText('Top Gun: Maverick')).toBeInTheDocument();
    });
  });

  test('movies can be displayed from backend API', async () => {
    render(<App />);

    expect(screen.getByText(/Loading movies.../i)).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Top Gun: Maverick')).toBeInTheDocument();
    });

    expect(screen.getByText('Sonic the Hedgehog')).toBeInTheDocument();
    expect(screen.getByText('A Quiet Place')).toBeInTheDocument();
  });

  test('displays error message when API call fails', async () => {
    global.fetch.mockImplementationOnce(() =>
      Promise.reject(new Error('Network error'))
    );

    render(<App />);

    await waitFor(() => {
      expect(
        screen.getByText(/Failed to load movies: Network error/i)
      ).toBeInTheDocument();
    });
  });
});
