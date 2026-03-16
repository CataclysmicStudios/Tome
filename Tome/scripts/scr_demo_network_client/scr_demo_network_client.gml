/// @title Network Client
/// @category Object Orientation

/// @constructor
/// @func NetworkClient(port, [max_peers])
/// @desc A comprehensive networking interface for managing connections, data streams, and security protocols.
/// @param {real} port The local port to bind the socket to.
/// @param {real} [max_peers] The maximum number of allowed connections. Defaults to 16.
function NetworkClient(_port, _max_peers = 16) constructor {
    port = _port;
    max_peers = _max_peers;
    is_active = false;

    /// @method start_service()
    /// @desc Initializes the socket and begins listening for traffic. This method is intentionally left ungrouped.
    /// @return {bool} True if the service started successfully.
    static start_service = function() {}

    /// @method connect_to_host(ip_address, [timeout])
    /// @group Connection Management
    /// @desc Attempts to establish a connection with a remote server.
    /// @param {string} ip_address The IPv4 address of the target host.
    /// @param {real} [timeout] Connection timeout in milliseconds. Defaults to 5000.
    /// @return {bool}
    static connect_to_host = function(_ip_address, _timeout = 5000) {}

    /// @method send_packet(payload, [reliable])
    /// @group Data Transmission
    /// @desc Dispatches a data payload to the connected host.
    /// @param {string | buffer} payload The data to transmit.
    /// @param {bool} [reliable] If true, uses TCP-like guaranteed delivery. Defaults to false (UDP).
    /// @return {real} Bytes sent.
    static send_packet = function(_payload, _reliable = false) {}

    /// @method generate_handshake_keys()
    /// @group Security
    /// @desc Generates an asymmetric key pair for the initial handshake.
    /// @return {undefined}
    static generate_handshake_keys = function() {}

    /// @method disconnect([reason])
    /// @group Connection Management
    /// @desc Severs the current connection and cleans up the socket.
    /// @param {string} [reason] An optional message sent to the host explaining the disconnect.
    /// @return {undefined}
    static disconnect = function(_reason = "") {}

    /// @method receive_packet()
    /// @group Data Transmission
    /// @desc Polls the internal queue for incoming data.
    /// @return {buffer | undefined} Returns the packet buffer, or undefined if the queue is empty.
    static receive_packet = function() {}

    /// @method get_status_code()
    /// @desc Retrieves the current internal state code of the client. This method is intentionally left ungrouped.
    /// @return {real} The state code.
    static get_status_code = function() {}

    /// @method encrypt_stream(key, [algorithm])
    /// @group Security
    /// @desc Applies continuous encryption to all outgoing packets.
    /// @param {string} key The private key to use.
    /// @param {string | real} [algorithm] The cipher to use. Defaults to AES-256.
    /// @return {bool}
    static encrypt_stream = function(_key, _algorithm = "AES-256") {}

    /// @method ping_host([host_ip])
    /// @group Connection Management
    /// @desc Sends an ICMP echo request to measure latency.
    /// @param {string} [host_ip] The IP to ping. Defaults to the currently connected host.
    /// @return {real} Latency in milliseconds.
    static ping_host = function(_host_ip = undefined) {}

    /// @method broadcast_message(message, [channels])
    /// @group Data Transmission
    /// @desc Sends a global message across all active sub-channels.
    /// @param {string} message The text to broadcast.
    /// @param {Array.real} [channels] An array of specific channel IDs to restrict the broadcast to.
    /// @return {undefined}
    static broadcast_message = function(_message, _channels = []) {}

    /// @method verify_certificate(cert_string)
    /// @group Security
    /// @desc Validates the authenticity of the host's SSL/TLS certificate.
    /// @param {string} cert_string The raw certificate data.
    /// @return {bool} True if the certificate is signed and valid.
    static verify_certificate = function(_cert_string) {}
}