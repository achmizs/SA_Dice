//
//  SA_DiceBot.m
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import "SA_DiceBot.h"

#import "SA_BotDelegate.h"
#import "SA_CommandResponder.h"
#import "SA_BotCommandResponder.h"
#import "SA_LegacyCommandResponder.h"
#import "SA_ErrorCatalog.h"
#import "NSString+SA_NSStringExtensions.h"
#import "NSRange-Conventional.h"

/*********************************************/
#pragma mark - SA_DiceBot class implementation
/*********************************************/

@implementation SA_DiceBot

/**************************/
#pragma mark - Initializers
/**************************/

- (instancetype)init
{
	return [self initWithName:@"DIE_BOT"];
}

- (instancetype)initWithName:(NSString *)name
{
	if(self = [super initWithName:name])
	{
		NSLog(NSLocalizedString(@"Initializing SA_DiceBot with name \"%@\"", @"{display name of the bot}"), name);
		
		self.commandDesignatorCharacters = @".!/";
		
		[self loadDefaultCommandResponders];
	}
	return self;
}

/****************************/
#pragma mark - Public methods
/****************************/

- (void)message:(NSString *)messageBody withInfo:(NSDictionary *)messageInfo
{
	if([messageBody isEqualToString:@""])
	{
		// Ignore empty messages.
	}
	else
	{
		NSRange commandRange;
		BOOL byName;
		
		// Is the message a possible command? That is, does it start with any of 
		// the permitted initial characters that designate a command?
		NSString *firstChar = [messageBody substringToIndex:1];
		if([self.commandDesignatorCharacters containsCharactersInString:firstChar])
		{
			commandRange = NSMakeRange(1, messageBody.length - 1);
			byName = NO;
		}
		else
		{
			// We also recognize commands that come after mentions of the bot's
			// name at the beginning of the message.
			NSRange possibleNameRange = NSRangeMake(0, self.name.length);
			if(messageBody.length > self.name.length && 
			   [[messageBody substringWithRange:possibleNameRange] isEqualToString:self.name])
			{
				commandRange = [messageBody rangeToEndFrom:[messageBody firstNonWhitespaceAfterRange:[messageBody firstWhitespaceAfterRange:possibleNameRange]]];
				byName = YES;
			}
			else
			{
				// Does not begin with a command. Ignore.
				return;
			}
		}
		
		// Extract the part of the string that is the actual command.
		NSString *commandString = [messageBody substringWithRange:commandRange];
		
		// Get the replies for this command.
		NSArray <NSDictionary *> *replies = [self repliesForCommandString:commandString messageInfo:messageInfo byName:byName];
		
		// Send the replies.
		[replies enumerateObjectsUsingBlock:^(NSDictionary *reply, NSUInteger idx, BOOL *stop) {
			[self.delegate SA_botMessage:reply[SA_DB_MESSAGE_BODY] 
									from:self 
								withInfo:reply[SA_DB_MESSAGE_INFO]];
		}];
	}
}

/****************************/
#pragma mark - Helper methods
/****************************/

- (NSArray <NSDictionary *> *)repliesForCommandString:(NSString *)commandString messageInfo:(NSDictionary *)messageInfo byName:(BOOL)byName
{
	NSError *error;
	NSArray <NSDictionary *> *replies = [self.botCommandresponder repliesForCommandString:commandString messageInfo:messageInfo error:&error];
	
	if(error && error.code == SA_DiceBotErrorUnknownCommand)
	{
		error = nil;
		replies = [self.currentCommandResponder repliesForCommandString:commandString messageInfo:messageInfo error:&error];
	}
	
	if(error)
	{
		// Is outputting the provided error the right way to do error handling
		// here? I don't know. Maybe not. For now, that's what it is.
		NSString *errorReply = [NSString stringWithFormat:NSLocalizedString(@"ERROR: %@ (%@ %@)", @"{description}, {failure reason}, {recovery suggestion}"),
								error.localizedDescription, 
								error.localizedFailureReason,
								error.localizedRecoverySuggestion];
		
		replies = [replies arrayByAddingObject:@{ SA_DB_MESSAGE_BODY	: errorReply,
												  SA_DB_MESSAGE_INFO	: messageInfo }];
	}
	
	return replies;
}

- (void)loadDefaultCommandResponders
{
	self.legacyCommandResponder = [SA_LegacyCommandResponder new];
	self.botCommandresponder = [SA_BotCommandResponder new];
	
	// The default command responder, in the current implementation, is the 
	// legacy command responder.
	self.currentCommandResponder = self.legacyCommandResponder;
}

@end
