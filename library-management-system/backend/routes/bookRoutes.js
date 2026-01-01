const express = require('express');
const router = express.Router();
const Book = require('../models/Book');

// ============================================
// GET /api/books - Retrieve all books
// ============================================
router.get('/books', async (req, res) => {
  try {
    console.log('📖 GET /api/books - Fetching all books');
    
    const { category, author, search, sort } = req.query;
    
    // Build filter object
    let filter = {};
    
    if (category) {
      filter.category = category;
    }
    
    if (author) {
      filter.author = { $regex: author, $options: 'i' }; // Case-insensitive search
    }
    
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { author: { $regex: search, $options: 'i' } },
        { isbn: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }
    
    // Build sort object
    let sortObj = {};
    if (sort) {
      switch (sort) {
        case 'title-asc':
          sortObj = { title: 1 };
          break;
        case 'title-desc':
          sortObj = { title: -1 };
          break;
        case 'newest':
          sortObj = { createdAt: -1 };
          break;
        case 'oldest':
          sortObj = { createdAt: 1 };
          break;
        case 'available':
          sortObj = { availableCopies: -1 };
          break;
        default:
          sortObj = { createdAt: -1 };
      }
    } else {
      sortObj = { createdAt: -1 }; // Default sort by newest
    }
    
    // Fetch books from database
    const books = await Book.find(filter).sort(sortObj).select('-__v');
    
    console.log(`✅ Found ${books.length} books`);
    
    res.status(200).json({
      success: true,
      count: books.length,
      data: books,
      message: `Retrieved ${books.length} books successfully`,
    });
  } catch (error) {
    console.error('❌ Error fetching books:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error fetching books from database',
      message: error.message,
    });
  }
});

// ============================================
// POST /api/books - Add a new book
// ============================================
router.post('/books', async (req, res) => {
  try {
    console.log('📚 POST /api/books - Adding new book');
    console.log('Request body:', req.body);
    
    // Validate required fields
    const { title, author, isbn, publishedYear } = req.body;
    
    if (!title || !author || !isbn || !publishedYear) {
      console.warn('⚠️  Missing required fields');
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'Please provide title, author, isbn, and publishedYear',
        requiredFields: {
          title: !title ? 'required' : 'provided',
          author: !author ? 'required' : 'provided',
          isbn: !isbn ? 'required' : 'provided',
          publishedYear: !publishedYear ? 'required' : 'provided',
        },
      });
    }
    
    // Check if book with same ISBN already exists
    const existingBook = await Book.findOne({ isbn });
    if (existingBook) {
      console.warn(`⚠️  Book with ISBN ${isbn} already exists`);
      return res.status(409).json({
        success: false,
        error: 'Duplicate ISBN',
        message: `A book with ISBN ${isbn} already exists in the database`,
        existingBook: existingBook,
      });
    }
    
    // Set default values for optional fields
    const bookData = {
      title: title.trim(),
      author: author.trim(),
      isbn: isbn.trim(),
      publishedYear: parseInt(publishedYear),
      category: req.body.category || 'Other',
      description: req.body.description ? req.body.description.trim() : '',
      totalCopies: req.body.totalCopies ? parseInt(req.body.totalCopies) : 1,
    };
    
    // Calculate available copies
    bookData.availableCopies = bookData.totalCopies;
    
    // Create new book
    const newBook = new Book(bookData);
    
    // Save to database
    const savedBook = await newBook.save();
    
    console.log(`✅ Book added successfully with ID: ${savedBook._id}`);
    
    res.status(201).json({
      success: true,
      message: 'Book added successfully',
      data: savedBook,
    });
  } catch (error) {
    console.error('❌ Error adding book:', error.message);
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((err) => err.message);
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: messages,
      });
    }
    
    // Handle duplicate key error
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0];
      return res.status(409).json({
        success: false,
        error: 'Duplicate field',
        message: `${field} already exists`,
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Error adding book',
      message: error.message,
    });
  }
});

// ============================================
// DELETE /api/books/:id - Delete a book by ID
// ============================================
router.delete('/books/:id', async (req, res) => {
  try {
    console.log(`🗑️  DELETE /api/books/${req.params.id} - Deleting book`);
    
    const { id } = req.params;
    
    // Validate MongoDB ObjectId format
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      console.warn('⚠️  Invalid book ID format');
      return res.status(400).json({
        success: false,
        error: 'Invalid book ID',
        message: 'Please provide a valid MongoDB ObjectId',
      });
    }
    
    // Find and delete the book
    const deletedBook = await Book.findByIdAndDelete(id);
    
    // Check if book exists
    if (!deletedBook) {
      console.warn(`⚠️  Book with ID ${id} not found`);
      return res.status(404).json({
        success: false,
        error: 'Book not found',
        message: `No book found with ID: ${id}`,
      });
    }
    
    console.log(`✅ Book deleted successfully: ${deletedBook.title}`);
    
    res.status(200).json({
      success: true,
      message: 'Book deleted successfully',
      data: deletedBook,
    });
  } catch (error) {
    console.error('❌ Error deleting book:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error deleting book',
      message: error.message,
    });
  }
});

// ============================================
// GET /api/books/:id - Get a single book by ID
// ============================================
router.get('/books/:id', async (req, res) => {
  try {
    console.log(`📖 GET /api/books/${req.params.id} - Fetching single book`);
    
    const { id } = req.params;
    
    // Validate MongoDB ObjectId format
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      console.warn('⚠️  Invalid book ID format');
      return res.status(400).json({
        success: false,
        error: 'Invalid book ID',
        message: 'Please provide a valid MongoDB ObjectId',
      });
    }
    
    // Find the book
    const book = await Book.findById(id);
    
    if (!book) {
      console.warn(`⚠️  Book with ID ${id} not found`);
      return res.status(404).json({
        success: false,
        error: 'Book not found',
        message: `No book found with ID: ${id}`,
      });
    }
    
    console.log(`✅ Book found: ${book.title}`);
    
    res.status(200).json({
      success: true,
      message: 'Book retrieved successfully',
      data: book,
    });
  } catch (error) {
    console.error('❌ Error fetching book:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error fetching book',
      message: error.message,
    });
  }
});

// ============================================
// PUT /api/books/:id - Update a book
// ============================================
router.put('/books/:id', async (req, res) => {
  try {
    console.log(`✏️  PUT /api/books/${req.params.id} - Updating book`);
    
    const { id } = req.params;
    const updateData = req.body;
    
    // Validate MongoDB ObjectId format
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      console.warn('⚠️  Invalid book ID format');
      return res.status(400).json({
        success: false,
        error: 'Invalid book ID',
        message: 'Please provide a valid MongoDB ObjectId',
      });
    }
    
    // Find and update the book
    const updatedBook = await Book.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true }
    );
    
    if (!updatedBook) {
      console.warn(`⚠️  Book with ID ${id} not found`);
      return res.status(404).json({
        success: false,
        error: 'Book not found',
        message: `No book found with ID: ${id}`,
      });
    }
    
    console.log(`✅ Book updated successfully: ${updatedBook.title}`);
    
    res.status(200).json({
      success: true,
      message: 'Book updated successfully',
      data: updatedBook,
    });
  } catch (error) {
    console.error('❌ Error updating book:', error.message);
    
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((err) => err.message);
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: messages,
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Error updating book',
      message: error.message,
    });
  }
});

// ============================================
// GET /api/stats/summary - Get book statistics
// ============================================
router.get('/stats/summary', async (req, res) => {
  try {
    console.log('📊 GET /api/stats/summary - Fetching statistics');
    
    const stats = await Book.aggregate([
      {
        $group: {
          _id: null,
          totalBooks: { $sum: 1 },
          totalCopies: { $sum: '$totalCopies' },
          availableCopies: { $sum: '$availableCopies' },
          borrowedCopies: {
            $sum: {
              $subtract: ['$totalCopies', '$availableCopies'],
            },
          },
          averageYear: { $avg: '$publishedYear' },
        },
      },
      {
        $project: {
          _id: 0,
          totalBooks: 1,
          totalCopies: 1,
          availableCopies: 1,
          borrowedCopies: 1,
          averageYear: { $round: ['$averageYear', 0] },
          availability: {
            $cond: [
              { $eq: ['$totalCopies', 0] },
              0,
              { $round: [{ $divide: ['$availableCopies', '$totalCopies'] }, 2] },
            ],
          },
        },
      },
    ]);
    
    console.log(`✅ Statistics retrieved successfully`);
    
    res.status(200).json({
      success: true,
      message: 'Statistics retrieved successfully',
      data: stats[0] || {
        totalBooks: 0,
        totalCopies: 0,
        availableCopies: 0,
        borrowedCopies: 0,
        averageYear: 0,
        availability: 0,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching statistics:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error fetching statistics',
      message: error.message,
    });
  }
});

module.exports = router;
