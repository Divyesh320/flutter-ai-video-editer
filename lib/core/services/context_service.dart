import '../models/message.dart';

/// Interface for vector database operations
/// 
/// This abstract class defines the contract for vector storage and retrieval.
/// Implementations can use Pinecone, Supabase, or other vector databases.
abstract class VectorStore {
  /// Store a text chunk with its embedding
  Future<String> storeChunk(TextChunk chunk, List<double> embedding);
  
  /// Query for similar chunks based on a query embedding
  /// Returns chunks sorted by similarity (most similar first)
  Future<List<TextChunk>> querySimilar({
    required List<double> queryEmbedding,
    required String conversationId,
    int topK = 5,
  });
  
  /// Delete all chunks for a conversation
  Future<void> deleteConversationChunks(String conversationId);
}

/// Interface for generating embeddings from text
abstract class EmbeddingService {
  /// Generate an embedding vector for the given text
  Future<List<double>> generateEmbedding(String text);
}

/// Represents a chunk of text with its embedding information
class TextChunk {
  const TextChunk({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.tokenCount,
    this.messageId,
    this.vectorId,
  });

  /// Unique chunk identifier
  final String id;

  /// ID of the conversation this chunk belongs to
  final String conversationId;

  /// The text content of the chunk
  final String text;

  /// Number of tokens in this chunk
  final int tokenCount;

  /// Optional reference to the source message
  final String? messageId;

  /// ID in the vector database
  final String? vectorId;
}

/// Result of building context for LLM
class ContextResult {
  const ContextResult({
    required this.messages,
    required this.totalTokens,
    required this.retrievedChunks,
    required this.includedMostRecentUserMessage,
  });

  /// Messages included in context (most recent first in original order)
  final List<Message> messages;

  /// Total token count of included messages
  final int totalTokens;

  /// Chunks retrieved from vector DB for long conversations
  final List<TextChunk> retrievedChunks;

  /// Whether the most recent user message was included
  final bool includedMostRecentUserMessage;
}

/// Service for building LLM context with token budgeting and text chunking
/// 
/// Implements:
/// - Property 3: Context Window Token Budgeting
/// - Property 25: Text Chunking Token Bounds
class ContextService {
  ContextService({
    this.tokensPerChar = 0.25,
    this.minChunkTokens = 500,
    this.maxChunkTokens = 1000,
  });

  /// Approximate tokens per character (conservative estimate)
  /// GPT models average ~4 chars per token, so 0.25 tokens per char
  final double tokensPerChar;

  /// Minimum tokens per chunk for embeddings
  final int minChunkTokens;

  /// Maximum tokens per chunk for embeddings
  final int maxChunkTokens;

  /// Estimate token count for a string
  /// Uses a simple character-based estimation
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    // Conservative estimate: ~4 characters per token on average
    return (text.length * tokensPerChar).ceil();
  }

  /// Estimate token count for a message (includes role overhead)
  int estimateMessageTokens(Message message) {
    // Add overhead for role and formatting (~4 tokens)
    const roleOverhead = 4;
    return estimateTokens(message.content) + roleOverhead;
  }

  /// Build context from messages within a token budget
  /// 
  /// **Property 3: Context Window Token Budgeting**
  /// For any conversation history and token budget N, the context builder 
  /// SHALL include messages such that total tokens ≤ N, prioritizing most 
  /// recent messages, and the resulting context SHALL always include at 
  /// least the most recent user message.
  /// 
  /// **Validates: Requirements 2.2**
  ContextResult buildContext({
    required List<Message> messages,
    required int tokenBudget,
    List<TextChunk> retrievedChunks = const [],
  }) {
    if (messages.isEmpty) {
      return ContextResult(
        messages: [],
        totalTokens: 0,
        retrievedChunks: retrievedChunks,
        includedMostRecentUserMessage: false,
      );
    }

    // Sort messages by creation time (most recent last)
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Find the most recent user message
    Message? mostRecentUserMessage;
    for (var i = sortedMessages.length - 1; i >= 0; i--) {
      if (sortedMessages[i].role == MessageRole.user) {
        mostRecentUserMessage = sortedMessages[i];
        break;
      }
    }

    final includedMessages = <Message>[];
    var totalTokens = 0;
    var includedMostRecentUserMessage = false;

    // First, ensure we include the most recent user message if budget allows
    if (mostRecentUserMessage != null) {
      final userMsgTokens = estimateMessageTokens(mostRecentUserMessage);
      if (userMsgTokens <= tokenBudget) {
        totalTokens = userMsgTokens;
        includedMostRecentUserMessage = true;
      }
    }

    // Build context from most recent messages backwards
    for (var i = sortedMessages.length - 1; i >= 0; i--) {
      final message = sortedMessages[i];
      final messageTokens = estimateMessageTokens(message);

      // Skip if already counted (most recent user message)
      if (includedMostRecentUserMessage && 
          message.id == mostRecentUserMessage?.id &&
          includedMessages.isEmpty) {
        includedMessages.insert(0, message);
        continue;
      }

      // Check if adding this message would exceed budget
      if (totalTokens + messageTokens <= tokenBudget) {
        totalTokens += messageTokens;
        // Insert at beginning to maintain chronological order
        if (!includedMessages.contains(message)) {
          includedMessages.insert(0, message);
        }
      } else {
        // Budget exceeded, stop adding messages
        break;
      }
    }

    return ContextResult(
      messages: includedMessages,
      totalTokens: totalTokens,
      retrievedChunks: retrievedChunks,
      includedMostRecentUserMessage: includedMostRecentUserMessage,
    );
  }


  /// Chunk text into segments for embedding storage
  /// 
  /// **Property 25: Text Chunking Token Bounds**
  /// For any text input to the chunking function, all resulting chunks 
  /// SHALL have token count in the range [500, 1000], except for the 
  /// final chunk which may be smaller if the remaining text is < 500 tokens.
  /// 
  /// **Validates: Requirements 9.5**
  List<TextChunk> chunkText({
    required String text,
    required String conversationId,
    String? messageId,
  }) {
    if (text.isEmpty) {
      return [];
    }

    final totalTokens = estimateTokens(text);
    
    // If text is smaller than min chunk size, return as single chunk
    if (totalTokens < minChunkTokens) {
      return [
        TextChunk(
          id: '${conversationId}_chunk_0',
          conversationId: conversationId,
          text: text,
          tokenCount: totalTokens,
          messageId: messageId,
        ),
      ];
    }

    final chunks = <TextChunk>[];
    var currentPosition = 0;
    var chunkIndex = 0;

    // Calculate approximate characters per target chunk
    // Target middle of range for optimal chunking
    final targetTokens = (minChunkTokens + maxChunkTokens) ~/ 2;
    final charsPerToken = 1 / tokensPerChar;

    while (currentPosition < text.length) {
      // Calculate target end position based on token target
      final targetChars = (targetTokens * charsPerToken).round();
      var endPosition = currentPosition + targetChars;

      // Don't exceed text length
      if (endPosition >= text.length) {
        endPosition = text.length;
      } else {
        // Try to break at a sentence or word boundary
        endPosition = _findBreakPoint(text, currentPosition, endPosition);
      }

      final chunkText = text.substring(currentPosition, endPosition).trim();
      
      if (chunkText.isNotEmpty) {
        final chunkTokens = estimateTokens(chunkText);
        
        chunks.add(TextChunk(
          id: '${conversationId}_chunk_$chunkIndex',
          conversationId: conversationId,
          text: chunkText,
          tokenCount: chunkTokens,
          messageId: messageId,
        ));
        chunkIndex++;
      }

      currentPosition = endPosition;
      
      // Skip whitespace at the start of next chunk
      while (currentPosition < text.length && 
             text[currentPosition].trim().isEmpty) {
        currentPosition++;
      }
    }

    return chunks;
  }

  /// Find a good break point for chunking (sentence or word boundary)
  int _findBreakPoint(String text, int start, int targetEnd) {
    // Look for sentence boundaries first (within reasonable range)
    final searchStart = (targetEnd - 100).clamp(start, targetEnd);
    final searchEnd = (targetEnd + 100).clamp(targetEnd, text.length);
    
    // Look for sentence endings
    for (var i = targetEnd; i >= searchStart; i--) {
      if (i < text.length && _isSentenceEnd(text, i)) {
        return i + 1;
      }
    }
    
    // Look forward for sentence ending
    for (var i = targetEnd; i < searchEnd; i++) {
      if (_isSentenceEnd(text, i)) {
        return i + 1;
      }
    }

    // Fall back to word boundary
    for (var i = targetEnd; i >= searchStart; i--) {
      if (i < text.length && text[i] == ' ') {
        return i;
      }
    }

    // Last resort: use target position
    return targetEnd;
  }

  /// Check if position is end of a sentence
  bool _isSentenceEnd(String text, int position) {
    if (position >= text.length) return false;
    final char = text[position];
    return char == '.' || char == '!' || char == '?';
  }

  /// Default context window limit (in messages) before triggering vector retrieval
  static const int defaultContextWindowLimit = 10;

  /// Check if conversation exceeds context window limit
  /// 
  /// **Property 5: Vector Retrieval for Long Conversations**
  /// For any conversation where message count exceeds the Context_Window limit,
  /// the system SHALL retrieve at least 1 semantically relevant chunk from 
  /// Vector_DB to include in the LLM context.
  /// 
  /// **Validates: Requirements 2.4**
  bool exceedsContextWindowLimit(List<Message> messages, {int? limit}) {
    return messages.length > (limit ?? defaultContextWindowLimit);
  }

  /// Build context with vector retrieval for long conversations
  /// 
  /// This method extends buildContext by automatically retrieving relevant
  /// chunks from the vector store when the conversation exceeds the context
  /// window limit.
  /// 
  /// **Property 5: Vector Retrieval for Long Conversations**
  /// **Validates: Requirements 2.4**
  Future<ContextResult> buildContextWithVectorRetrieval({
    required List<Message> messages,
    required int tokenBudget,
    required VectorStore vectorStore,
    required EmbeddingService embeddingService,
    required String conversationId,
    int contextWindowLimit = defaultContextWindowLimit,
    int topK = 3,
  }) async {
    // Check if we need vector retrieval
    final needsVectorRetrieval = exceedsContextWindowLimit(
      messages, 
      limit: contextWindowLimit,
    );

    List<TextChunk> retrievedChunks = [];

    if (needsVectorRetrieval && messages.isNotEmpty) {
      // Get the most recent user message for query
      final sortedMessages = List<Message>.from(messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      String? queryText;
      for (var i = sortedMessages.length - 1; i >= 0; i--) {
        if (sortedMessages[i].role == MessageRole.user) {
          queryText = sortedMessages[i].content;
          break;
        }
      }

      if (queryText != null) {
        // Generate embedding for the query
        final queryEmbedding = await embeddingService.generateEmbedding(queryText);
        
        // Retrieve similar chunks from vector store
        retrievedChunks = await vectorStore.querySimilar(
          queryEmbedding: queryEmbedding,
          conversationId: conversationId,
          topK: topK,
        );
      }
    }

    // Build context with retrieved chunks
    return buildContext(
      messages: messages,
      tokenBudget: tokenBudget,
      retrievedChunks: retrievedChunks,
    );
  }

  /// Store message content as chunks in vector database
  /// 
  /// This method chunks the message content and stores each chunk
  /// with its embedding in the vector store.
  Future<List<TextChunk>> storeMessageChunks({
    required Message message,
    required VectorStore vectorStore,
    required EmbeddingService embeddingService,
  }) async {
    // Chunk the message content
    final chunks = chunkText(
      text: message.content,
      conversationId: message.conversationId,
      messageId: message.id,
    );

    // Store each chunk with its embedding
    final storedChunks = <TextChunk>[];
    for (final chunk in chunks) {
      final embedding = await embeddingService.generateEmbedding(chunk.text);
      final vectorId = await vectorStore.storeChunk(chunk, embedding);
      
      storedChunks.add(TextChunk(
        id: chunk.id,
        conversationId: chunk.conversationId,
        text: chunk.text,
        tokenCount: chunk.tokenCount,
        messageId: chunk.messageId,
        vectorId: vectorId,
      ));
    }

    return storedChunks;
  }
}
