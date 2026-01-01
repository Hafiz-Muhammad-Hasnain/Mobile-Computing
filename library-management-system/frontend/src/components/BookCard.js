import React from 'react';

function BookCard({ book, onDelete }) {
  return (
    <div className="bg-gradient-to-br from-white to-gray-50 rounded-lg shadow-md hover:shadow-xl transition-shadow duration-300 p-6 border-l-4 border-indigo-600">
      {/* Book Header */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-bold text-gray-800 mb-1">{book.title}</h3>
          <p className="text-gray-600 font-semibold">by {book.author}</p>
        </div>
      </div>

      {/* Book Details Grid */}
      <div className="grid grid-cols-2 gap-4 mb-4 py-4 border-y border-gray-200">
        {/* ISBN */}
        <div>
          <p className="text-gray-500 text-sm font-semibold">ISBN</p>
          <p className="text-gray-800 font-mono text-sm">{book.isbn || 'N/A'}</p>
        </div>

        {/* Published Year */}
        <div>
          <p className="text-gray-500 text-sm font-semibold">Published</p>
          <p className="text-gray-800 font-semibold">{book.publishedYear || 'N/A'}</p>
        </div>

        {/* Available Copies */}
        <div>
          <p className="text-gray-500 text-sm font-semibold">Total Copies</p>
          <p className="text-gray-800 font-semibold text-lg">{book.totalCopies || 0}</p>
        </div>

        {/* Available Copies Display */}
        {book.availableCopies !== undefined && (
          <div>
            <p className="text-gray-500 text-sm font-semibold">Available</p>
            <p className={`font-semibold text-lg ${
              book.availableCopies > 0 ? 'text-green-600' : 'text-red-600'
            }`}>
              {book.availableCopies} copies
            </p>
          </div>
        )}
      </div>

      {/* Action Buttons */}
      <div className="flex gap-3 pt-4">
        <button
          onClick={() => onDelete(book._id)}
          className="flex-1 bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded-lg transition duration-300 transform hover:scale-105 flex items-center justify-center gap-2"
        >
          🗑️ Delete
        </button>
        <button
          className="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg transition duration-300 transform hover:scale-105 flex items-center justify-center gap-2"
        >
          📖 View Details
        </button>
      </div>
    </div>
  );
}

export default BookCard;














