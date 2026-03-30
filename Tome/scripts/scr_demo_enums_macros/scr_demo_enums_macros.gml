/// @title Global Definitions
/// @category Constants & Data

/// @text ## Global Constants
/// 
/// This page serves as a reference for all engine-level macros and enumerators used throughout the Tome test suite.

/// @text ### System Macros
/// 
/// These macros define the core operational limits, default values, and bitwise flags for the various systems.
/// 
/// | Macro Name | Value | Description |
/// | --- | --- | --- |
/// | `MAX_RECURSION_DEPTH` | 128 | The absolute limit for recursive tree traversal. |
/// | `DEFAULT_TIMEOUT_MS` | 5000 | Milliseconds before a socket connection drops. |
/// | `BUFFER_CHUNK_SIZE` | 4096 | Default byte size for new memory allocations. |
/// | `FLAG_READ_ONLY` | 1 | Bitwise flag to lock a buffer from being written to. |
/// | `FLAG_ENCRYPTED` | 2 | Bitwise flag indicating the payload is AES-256 encrypted. |

/// @text ### Core Enumerators
/// 
/// Enumerators are strictly used for internal state management, event routing, and error handling.
/// Below is the primary state machine enum used by the `NetworkClient` constructor.
/// 
/// ```gml
/// enum NETWORK_STATE {
///     OFFLINE,
///     CONNECTING,
///     AUTHENTICATING,
///     CONNECTED,
///     DISCONNECTING,
///     ERROR_TIMEOUT
/// }
/// ```

/// @text #### Error Codes
/// 
/// Used by system methods like `get_status_code()` to identify specific failure points during execution.
/// 
/// ```gml
/// enum ERR_CODE {
///     NONE = 0,
///     OUT_OF_MEMORY = 1,
///     ACCESS_DENIED = 2,
///     INVALID_PAYLOAD = 3,
///     CONNECTION_LOST = 4
/// }
/// ```

/// @text #### Input Masks
/// 
/// If you prefer using the native Tome `@code` tag instead of the raw markdown block, it is fully supported alongside the text blocks! 
/// 
/// ?> When using the `@code` tag, Tome assumes that you are writing gml, as such the resulting markdown will essentially be the same as writing ` ```gml`.
/// 
/// @code
/// @pass tags
/// @code enum INPUT_MASK {
///     UP = 1,
///     DOWN = 2,
///     LEFT = 4,
///     RIGHT = 8,
///     ACTION = 16
/// }
/// @pass false