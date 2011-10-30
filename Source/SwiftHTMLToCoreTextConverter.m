/*
    SwiftHTMLToCoreTextConverter.m
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SwiftHTMLToCoreTextConverter.h"

#include <libxml/HTMLparser.h>

enum {
    SwiftHTMLToCoreTextConverterTag_Unknown = 0,

    SwiftHTMLToCoreTextConverterTag_A,
    SwiftHTMLToCoreTextConverterTag_B,
    SwiftHTMLToCoreTextConverterTag_I,
    SwiftHTMLToCoreTextConverterTag_P,
    SwiftHTMLToCoreTextConverterTag_U,
    SwiftHTMLToCoreTextConverterTag_BR,
    SwiftHTMLToCoreTextConverterTag_LI,
    SwiftHTMLToCoreTextConverterTag_TAB,
    SwiftHTMLToCoreTextConverterTag_FONT,
    SwiftHTMLToCoreTextConverterTag_TEXTFORMAT
};
typedef NSInteger SwiftHTMLToCoreTextConverterTag;


@implementation SwiftHTMLToCoreTextConverter

+ (id) sharedInstance
{
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}


#pragma mark -
#pragma mark Parsing

- (void) _flush
{
    if ([m_characters length]) {
        CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

        if (m_underlineCount > 0) {
            CTUnderlineStyle style = kCTUnderlineStyleSingle;
            CFNumberRef single = CFNumberCreate(NULL, kCFNumberSInt32Type, &style);
            CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, single);
            CFRelease(single);
        }

        CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(m_baseFont);
        CTFontSymbolicTraits mask   = (kCTFontItalicTrait | kCTFontBoldTrait);
    
        if (m_boldCount   > 0)  traits |= kCTFontBoldTrait;
        if (m_italicCount > 0)  traits |= kCTFontItalicTrait;

        CTFontRef fontToUse = CTFontCreateCopyWithSymbolicTraits(m_baseFont, CTFontGetSize(m_baseFont), NULL, traits, mask);
        CFDictionarySetValue(attributes, kCTFontAttributeName, fontToUse);
        if (fontToUse) CFRelease(fontToUse);

        CFAttributedStringRef replacement = CFAttributedStringCreate(NULL, (__bridge CFStringRef)m_characters, attributes); 
        CFAttributedStringReplaceAttributedString(m_output, CFRangeMake(CFAttributedStringGetLength(m_output), 0), replacement);
        CFRelease(replacement);
        
        [m_characters release];
        m_characters = [[NSMutableString alloc] init];
        
        CFRelease(attributes);
    }
}


static SwiftHTMLToCoreTextConverterTag sGetTagForString(const xmlChar *inString)
{
    const char  c = toupper(inString[0]);
    const char *s = (const char *)inString;
    size_t length = strlen(s);

    if (     (c == 'A') && strncasecmp("A",          s, length))  return SwiftHTMLToCoreTextConverterTag_A;
    else if ((c == 'B') && strncasecmp("B",          s, length))  return SwiftHTMLToCoreTextConverterTag_B;
    else if ((c == 'B') && strncasecmp("BR",         s, length))  return SwiftHTMLToCoreTextConverterTag_BR;
    else if ((c == 'F') && strncasecmp("FONT",       s, length))  return SwiftHTMLToCoreTextConverterTag_FONT;
    else if ((c == 'I') && strncasecmp("I",          s, length))  return SwiftHTMLToCoreTextConverterTag_I;
    else if ((c == 'L') && strncasecmp("LI",         s, length))  return SwiftHTMLToCoreTextConverterTag_LI;
    else if ((c == 'P') && strncasecmp("P",          s, length))  return SwiftHTMLToCoreTextConverterTag_P;
    else if ((c == 'T') && strncasecmp("TAB",        s, length))  return SwiftHTMLToCoreTextConverterTag_TAB;
    else if ((c == 'T') && strncasecmp("TEXTFORMAT", s, length))  return SwiftHTMLToCoreTextConverterTag_TEXTFORMAT;
    else if ((c == 'U') && strncasecmp("U",          s, length))  return SwiftHTMLToCoreTextConverterTag_U;
    
    return SwiftHTMLToCoreTextConverterTag_Unknown;
}


static void sStartElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element, SwiftHTMLToCoreTextConverterTag tag)
{
    if (tag == SwiftHTMLToCoreTextConverterTag_A) {
        // Not yet implemented: Dynamic Text HTML <a> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_B) {
        [self _flush];  self->m_boldCount++;

    } else if (tag == SwiftHTMLToCoreTextConverterTag_BR) {
        [self->m_characters appendString:@"\n"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_FONT) {
        // Not yet implemented: Dynamic Text HTML <font> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_I) {
        [self _flush];  self->m_italicCount++;

    } else if (tag == SwiftHTMLToCoreTextConverterTag_LI) {
        [self->m_characters appendFormat:@"%C ", 0x2022];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_P) {
        // Not yet implemented: Dynamic Text HTML <p> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TAB) {
        [self->m_characters appendString:@"\t"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TEXTFORMAT) {
        // Not yet implemented: Dynamic Text HTML <textformat> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_U) {
        [self _flush];  self->m_underlineCount++;
    }
}


static void sEndElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element, SwiftHTMLToCoreTextConverterTag tag)
{
    if (tag == SwiftHTMLToCoreTextConverterTag_A) {
        // Not yet implemented: Dynamic Text HTML <a> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_B) {
        self->m_boldCount--;  [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_FONT) {
        // Not yet implemented: Dynamic Text HTML <font> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_I) {
        self->m_italicCount--;  [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_LI) {
        [self->m_characters appendString:@"\n"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_P) {
        // Not yet implemented: Dynamic Text HTML <p> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TEXTFORMAT) {
        // Not yet implemented: Dynamic Text HTML <textformat> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_U) {
        self->m_underlineCount--;  [self _flush];
    }
}


static void sHandleNode(SwiftHTMLToCoreTextConverter *self, xmlNodePtr node)
{
    if (node->type == XML_ELEMENT_NODE) {
        xmlElementPtr element = (xmlElementPtr)node;
        SwiftHTMLToCoreTextConverterTag tag = sGetTagForString(element->name);
        
        if (tag != SwiftHTMLToCoreTextConverterTag_Unknown) {
            sStartElement(self, element, tag);
        }

        if (node->children) {
            xmlNodePtr childNode = xmlFirstElementChild(node);
            while (childNode) {
                sHandleNode(self, childNode);
                childNode = xmlNextElementSibling(childNode);
            }
        }

        if (tag != SwiftHTMLToCoreTextConverterTag_Unknown) {
            sEndElement(self, element, tag);
        }

    } else if (node->type == XML_TEXT_NODE) {
        xmlChar *content = xmlNodeGetContent(node);

        if (content) {
            size_t length = strlen((const char *)content);

            NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)content length:length encoding:NSUTF8StringEncoding freeWhenDone:YES];
            [self->m_characters appendString:string];
            [string release];
        }
    }
     
}



- (CFAttributedStringRef) copyAttributedStringForHTML:(NSString *)string baseFont:(CTFontRef)font
{
    if (!string) return NULL;

    CFStringRef cfString = (__bridge CFStringRef)string;
    CFIndex     length   = 0;
    CFRange     range    = CFRangeMake(0, CFStringGetLength(cfString));

    CFStringGetBytes((__bridge CFStringRef)string, range, kCFStringEncodingUTF8, 0, 0, NULL, 0, &length);

    UInt8 *buffer = (UInt8 *)malloc(length);
    CFStringGetBytes(cfString, range, kCFStringEncodingUTF8, 0, 0, buffer, length, &length);
    
    htmlDocPtr htmlDoc = htmlReadMemory((const char *)buffer, length, NULL, "UTF-8", 0);
    
    m_characters = [[NSMutableString alloc] init];
    m_output     = CFAttributedStringCreateMutable(NULL, 0);
    
    if (font) {
        m_baseFont = CFRetain(font);
    } else {
        m_baseFont = CTFontCreateWithName(CFSTR("Helvetica"), 12.0, &CGAffineTransformIdentity);
    }

    if (htmlDoc) {
        sHandleNode(self, (xmlNodePtr)htmlDoc);
        xmlFreeDoc(htmlDoc);

        [self _flush];
    }

    CFRelease(m_baseFont);
    m_baseFont = NULL;
    
    CFAttributedStringRef output = m_output;
    m_output = NULL;

    [m_characters release];
    m_characters = nil;

    free(buffer);
    
    return output;
}

@end