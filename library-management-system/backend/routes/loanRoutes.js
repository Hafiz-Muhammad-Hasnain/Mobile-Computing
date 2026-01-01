const express = require('express');
const Loan = require('../models/Loan');
const Book = require('../models/Book');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Borrow a book
router.post('/borrow', authMiddleware, async (req, res) => {
  try {
    const { bookId } = req.body;
    const userId = req.user.id;

    const book = await Book.findById(bookId);
    if (!book || book.availableCopies === 0) {
      return res.status(400).json({ message: 'Book not available' });
    }

    // Calculate due date (14 days from now)
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 14);

    const loan = new Loan({
      userId,
      bookId,
      dueDate,
      status: 'active'
    });

    await loan.save();

    // Update available copies
    book.availableCopies -= 1;
    await book.save();

    res.status(201).json({ message: 'Book borrowed successfully', loan });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Return a book
router.post('/return/:loanId', authMiddleware, async (req, res) => {
  try {
    const loan = await Loan.findById(req.params.loanId);
    if (!loan) {
      return res.status(404).json({ message: 'Loan not found' });
    }

    if (loan.userId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    loan.returnDate = new Date();
    loan.status = 'returned';

    // Calculate fine if overdue
    if (new Date() > loan.dueDate) {
      const daysOverdue = Math.floor((new Date() - loan.dueDate) / (1000 * 60 * 60 * 24));
      loan.fineAmount = daysOverdue * 5; // $5 per day
    }

    await loan.save();

    // Update available copies
    const book = await Book.findById(loan.bookId);
    book.availableCopies += 1;
    await book.save();

    res.json({ message: 'Book returned successfully', loan });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get user's loans
router.get('/user/:userId', authMiddleware, async (req, res) => {
  try {
    if (req.user.id !== req.params.userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const loans = await Loan.find({ userId: req.params.userId })
      .populate('bookId')
      .populate('userId');
    res.json(loans);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get all loans (admin only)
router.get('/', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const loans = await Loan.find()
      .populate('bookId')
      .populate('userId');
    res.json(loans);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
