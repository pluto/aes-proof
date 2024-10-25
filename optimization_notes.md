## AES-GCM

After combing through these circuits and removing some unused components, tests, and outdatted comments. I have a few notes on what i think are good things to look into into.

### Redundant Intermediate Signals
I think the first thing is redundant intermediate signals. This is of course will come at a cost to redability but will be worth if we can reduce some of the heavily repeated intermediate signals in the more deeply nested components.

#### Stream and block dance
One place where we might have created some redundant intermediate signals is in our stream and block dance. The goal here would be to push complexity down such that we only do this transformation once and then in the lower components we are just opperating on blocks. I am not sure we are as most consistent as we could be and that we likely have some repeated transformations resulting in some redundant signals. There is some things to keep in mind here. For example, the J0 counter is just incrementing the last 32 bits of the previous counter block. I wrote a word adder that is in utils that handles this. But perhapse making sure it is more optimal for it to work on a stream or a block would be worth looking into.

### Folding
I think the other thing I am incline to look into is the folding. Now there might be some dragons here because tracy wrote the folding circuits so i don't have the greatest intuition on them. However they seem to be very similar to the non folding circuits with some minor differences in passing a "step_in" signal. I think we should try to fold the circuits and see if we can get a smaller circuit. I think that it is possible that we could within the the ghash foldable maybe instead fold the the gmul within the ghash since that has the most repeated components and has a lost of constraints. Ghash mul has `81552` constraints and is called for each cipher block (16 bytes of plain text). So if we can figure out how to fold the main loop in gmul so that we are folding each 128bit itteration then we could potentially reduce the constraints drastically (I hypothesize by a factor of 128). This does seem like it might need some careful thought and more work and should probably only come after we look for other low hanging fruit.

### Important to note
circom kit doesn't use circom compiler optimizations. So when you log constraints in these tests they are wrong.
The right way to get the "prod" compiled constraints is to use the circom compiler directly.
with this command:  `circom circuits/aes-gcm/aes-gcm.circom -l node_modules --r1cs`