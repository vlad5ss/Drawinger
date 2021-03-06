
#import "UIDrawingView.h"
#import "UIStyle.h"
#import "Extras.h"

@interface UIDrawingView ()

@property (nonatomic) NSMutableDictionary <NSString *, UIBezierPath *> *touchPaths;
@property (nonatomic) NSMutableArray <UIBezierPath *> *drawingPaths;
@property (nonatomic) UIImage *drawingStoreImage;
@property (nonatomic) UIImageView *drawingStoreImageView;
@property (nonatomic) CGFloat maxDimension;

@end

@implementation UIDrawingView

- (instancetype)init; { if (!(self = [super init])) { return nil; } return [self commonInit]; }
- (instancetype)initWithCoder:(NSCoder *)aDecoder; { if (!(self = [super initWithCoder:aDecoder])) { return nil; } return [self commonInit]; }
- (instancetype)initWithFrame:(CGRect)frame; { if (!(self = [super initWithFrame:frame])) { return nil; } return [self commonInit]; }

- (instancetype)commonInit;
{
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = UIColor.clearColor;
    self.maxDimension = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    self.drawingStoreImageView = [UIImageView.alloc initWithFrame:CGRectMake(0, 0, self.maxDimension, self.maxDimension)];
    self.drawingStoreImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.drawingStoreImageView.backgroundColor = UIColor.clearColor;
    self.drawingStoreImageView.contentMode = UIViewContentModeTopLeft;
    [self reset];
    return self;
}

- (void)reset;
{
    [self resetWithDrawingStyle:UIStyle.new];
}

- (void)resetWithDrawingStyle:(UIStyle *)style;
{
    self.touchPaths = NSMutableDictionary.new;
    self.drawingPaths = NSMutableArray.new;
    self.drawingStoreImage = nil;
    self.drawingStoreImageView.image = nil;
    self.currentDrawingStyle = style;

    [self setNeedsDisplay];
}

- (void)didMoveToSuperview;
{
    [super didMoveToSuperview];
    if (![self.superview.subviews containsObject:self.drawingStoreImageView]) {
        [self.superview insertSubview:self.drawingStoreImageView belowSubview:self];
    }
}

- (void)commitDrawingPaths;
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.maxDimension, self.maxDimension), NO, 0);
    [self.drawingStoreImage drawAtPoint:CGPointZero];
    [self drawRect:self.bounds];
    self.drawingStoreImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.drawingStoreImageView.image = self.drawingStoreImage;
    [self.drawingPaths removeAllObjects];
    [self setNeedsDisplay];
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
{
    [touches forEach:^(UITouch *touch) {
        UIBezierPath *path = [UIBezierPath newPathAtPoint:touch.location style:self.currentDrawingStyle];
        [path addCurveFromTouch:touch];
        self.touchPaths[touch.identifier] = path;
        [self.drawingPaths addObject:path];
    }];
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
{
    [touches forEach:^(UITouch *touch) { [self.touchPaths[touch.identifier] addCurveFromTouch:touch]; }];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
{
    [self touchesMoved:touches withEvent:event];
    [touches forEach:^(UITouch *touch) { self.touchPaths[touch.identifier] = nil; }];

    if (self.touchPaths.count == 0) {
        [self commitDrawingPaths];
    }
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    [self.drawingPaths forEach:^(UIBezierPath *path) { [path strokeWithCurrentStrokeColor]; }];
}

@end
