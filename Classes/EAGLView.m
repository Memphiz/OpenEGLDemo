/*
 
 File: EAGLView.m
 
 Abstract: The EAGLView class is a UIView subclass that renders OpenGL scene.
 If the current hardware supports OpenGL ES 2.0, it draws using OpenGL ES 2.0;
 otherwise it draws using OpenGL ES 1.1.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

#import "EAGLView.h"
#import "OpenEGLDemoAppliance.h"
#import "Shaders.h"
#include "matrix.h"

// uniform index
enum {
	UNIFORM_MODELVIEW_PROJECTION_MATRIX,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
	ATTRIB_VERTEX,
	ATTRIB_COLOR,
	NUM_ATTRIBUTES
};

@interface EAGLView (PrivateMethods)
- (void) setContext:(EAGLContext *)newContext;
- (void) createFramebuffer;
- (void) deleteFramebuffer;
- (BOOL) loadShaders;
@end

@implementation EAGLView

@synthesize animating;

// You must implement this method
+ (Class) layerClass
{
  return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithFrame:(CGRect)frame
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
  if ((self = [super initWithFrame:frame]))
  {
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithBool:FALSE], 
      kEAGLDrawablePropertyRetainedBacking, 
      kEAGLColorFormatRGBA8, 
      kEAGLDrawablePropertyColorFormat, nil];
		
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext)
      NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
      NSLog(@"Failed to set ES context current");
    
    self.context = aContext;
    [aContext release];

    [self setContext:context];
    [self createFramebuffer];
    [self setFramebuffer];
    [self loadShaders];

		animating = FALSE;
  }

  return self;
}

- (void) dealloc
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self deleteFramebuffer];    
  [context release];
  
  [super dealloc];
}

- (EAGLContext *)context
{
  return context;
}

- (void)setContext:(EAGLContext *)newContext
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
  if (context != newContext)
  {
    [self deleteFramebuffer];
    
    [context release];
    context = [newContext retain];
    
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)createFramebuffer
{
  if (context && !defaultFramebuffer)
  {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [EAGLContext setCurrentContext:context];
    
    // Create default framebuffer object.
    glGenFramebuffers(1, &defaultFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    
    // Create color render buffer and allocate backing store.
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
    NSLog(@"Width: %i, height: %i",framebufferWidth, framebufferHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
      NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
  }
}

- (void) deleteFramebuffer
{
  if (context)
  {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [EAGLContext setCurrentContext:context];
    
    if (defaultFramebuffer)
    {
      glDeleteFramebuffers(1, &defaultFramebuffer);
      defaultFramebuffer = 0;
    }
    
    if (colorRenderbuffer)
    {
      glDeleteRenderbuffers(1, &colorRenderbuffer);
      colorRenderbuffer = 0;
    }
  }
}

- (void) setFramebuffer
{
  if (context)
  {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glViewport(0, 0, framebufferWidth, framebufferHeight);
  }
}

- (bool) presentFramebuffer
{
  bool success = FALSE;
  
  if (context)
  {
    [EAGLContext setCurrentContext:context];
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    success = [context presentRenderbuffer:GL_RENDERBUFFER];
  }
  
  return success;
}

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;
	
	// create shader program
	program = glCreateProgram();
	
	// create and compile vertex shader
  vertShaderPathname = [[NSBundle bundleForClass:[OpenEGLDemoAppliance class]] pathForResource:@"template" ofType:@"vsh"];
  //NSLog(@"eglv2:loadShaders, vertShaderPathname=%@", vertShaderPathname);
	if (!compileShader(&vertShader, GL_VERTEX_SHADER, 1, vertShaderPathname)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// create and compile fragment shader
  fragShaderPathname = [[NSBundle bundleForClass:[OpenEGLDemoAppliance class]] pathForResource:@"template" ofType:@"fsh"];
  //NSLog(@"eglv2:loadShaders, fragShaderPathname=%@", fragShaderPathname);
	if (!compileShader(&fragShader, GL_FRAGMENT_SHADER, 1, fragShaderPathname)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// attach vertex shader to program
	glAttachShader(program, vertShader);
	
	// attach fragment shader to program
	glAttachShader(program, fragShader);
	
	// bind attribute locations
	// this needs to be done prior to linking
	glBindAttribLocation(program, ATTRIB_VERTEX, "position");
	glBindAttribLocation(program, ATTRIB_COLOR, "color");
	
	// link program
	if (!linkProgram(program)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// get uniform locations
	uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix");
	
	// release vertex and fragment shaders
	if (vertShader) {
		glDeleteShader(vertShader);
		vertShader = 0;
	}
	if (fragShader) {
		glDeleteShader(fragShader);
		fragShader = 0;
	}
	
	return YES;
}

- (void) drawFrame:(id)sender;
{
  // Replace the implementation of this method to do your own custom drawing
  const GLfloat squareVertices[] = {
      -0.5f, -0.5f,
      0.5f,  -0.5f,
      -0.5f,  0.5f,
      0.5f,   0.5f,
  };
  const GLubyte squareColors[] = {
      255, 255,   0, 255,
      0,   255, 255, 255,
      0,     0,   0,   0,
      255,   0, 255, 255,
  };

  [EAGLContext setCurrentContext:context];
  
  glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
  glViewport(0, 0, framebufferWidth, framebufferHeight);
  
  glClearColor(0.5f, 0.0f, 0.5f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
	
	// use shader program
	glUseProgram(program);
	
	// handle viewing matrices
	GLfloat proj[16], modelview[16], modelviewProj[16];
	// setup projection matrix (orthographic)
	mat4f_LoadOrtho(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f, proj);
	// setup modelview matrix (rotate around z)
	mat4f_LoadZRotation(rotz, modelview);
	// projection matrix * modelview matrix
	mat4f_MultiplyMat4f(proj, modelview, modelviewProj);
	rotz += 3.0f * M_PI / 180.0f;
	
	// update uniform values
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX], 1, GL_FALSE, modelviewProj);
	
	// update attribute values
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, 1, 0, squareColors); //enable the normalized flag
  glEnableVertexAttribArray(ATTRIB_COLOR);
	
	// Validate program before drawing. This is a good check, but only really necessary in a debug build.
	// DEBUG macro must be defined in your debug configurations if that's not already the case.
  #if defined(DEBUG)
    if (![self validateProgram:program])
    {
      NSLog(@"Failed to validate program: %d", program);
      return;
    }
  #endif
	
	// draw
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) startAnimation
{
	if (!animating)
	{
		animating = TRUE;
    // kick off an animation thread
    animationThreadLock = [[NSConditionLock alloc] initWithCondition: FALSE];
    animationThread = [[NSThread alloc] initWithTarget:self 
      selector:@selector(runAnimation:) 
      object:animationThreadLock];
    [animationThread start];
	}
}

- (void) stopAnimation
{
	if (animating)
	{
		animating = FALSE;
    // wait for animation thread to die
    if ([animationThread isFinished] == NO)
      [animationThreadLock lockWhenCondition:TRUE];
	}
}

- (void) runAnimation:(id) arg
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  NSLog(@"%s:enter", __PRETTY_FUNCTION__);

  NSConditionLock* myLock = arg;
  [myLock lock];
  
  while (animating)
  {
    if (context)
    {
      [self setFramebuffer];
      [self drawFrame:nil];
      [self presentFramebuffer];
    }
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.041666666666667];
    [NSThread sleepUntilDate:future];
  }
  [myLock unlockWithCondition:TRUE];

  NSLog(@"%s:exit", __PRETTY_FUNCTION__);

  [pool release];
}

@end
